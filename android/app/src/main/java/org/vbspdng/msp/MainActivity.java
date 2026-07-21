package org.vbspdng.msp;

import android.content.Context;
import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String SECURE_STORAGE_CHANNEL = "org.vbspdng.msp/secure_storage";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        SecureStorage secureStorage = new SecureStorage(getApplicationContext());

        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                SECURE_STORAGE_CHANNEL
        ).setMethodCallHandler((call, result) ->
                handleSecureStorageCall(secureStorage, call, result));
    }

    private void handleSecureStorageCall(
            SecureStorage storage,
            MethodCall call,
            MethodChannel.Result result
    ) {
        try {
            switch (call.method) {
                case "writeAll":
                    storage.writeAll(requireStringMap(call.argument("values")));
                    result.success(null);
                    break;
                case "readAll":
                    List<String> keys = requireStringList(call.argument("keys"));
                    try {
                        result.success(storage.readAll(keys));
                    } catch (Exception readError) {
                        // Corrupt or restored ciphertext must never be returned.
                        storage.resetEncryptedStorage();
                        result.success(new HashMap<String, String>());
                    }
                    break;
                case "deleteAll":
                    storage.deleteAll(requireStringList(call.argument("keys")));
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception error) {
            result.error(
                    "SECURE_STORAGE_ERROR",
                    "Secure storage operation failed",
                    error.getClass().getSimpleName()
            );
        }
    }

    private static Map<String, String> requireStringMap(Object value) {
        if (!(value instanceof Map)) {
            throw new IllegalArgumentException("values must be a map");
        }
        Map<String, String> result = new HashMap<>();
        for (Map.Entry<?, ?> entry : ((Map<?, ?>) value).entrySet()) {
            if (!(entry.getKey() instanceof String) || !(entry.getValue() instanceof String)) {
                throw new IllegalArgumentException("values must contain strings");
            }
            result.put((String) entry.getKey(), (String) entry.getValue());
        }
        return result;
    }

    private static List<String> requireStringList(Object value) {
        if (!(value instanceof List)) {
            throw new IllegalArgumentException("keys must be a list");
        }
        for (Object item : (List<?>) value) {
            if (!(item instanceof String)) {
                throw new IllegalArgumentException("keys must contain strings");
            }
        }
        @SuppressWarnings("unchecked")
        List<String> keys = (List<String>) value;
        return keys;
    }

    private static final class SecureStorage {
        private static final String ANDROID_KEY_STORE = "AndroidKeyStore";
        private static final String KEY_ALIAS = "org.vbspdng.msp.secure-storage-key";
        private static final String SECURE_PREFERENCES = "DngSecureStorage";
        private static final String LEGACY_PREFERENCES = "FlutterSharedPreferences";
        private static final String LEGACY_PREFIX = "flutter.";
        private static final String CIPHER_SUFFIX = ".ciphertext";
        private static final String IV_SUFFIX = ".iv";

        private final SharedPreferences securePreferences;
        private final SharedPreferences legacyPreferences;

        SecureStorage(Context context) {
            securePreferences = context.getSharedPreferences(
                    SECURE_PREFERENCES,
                    Context.MODE_PRIVATE
            );
            legacyPreferences = context.getSharedPreferences(
                    LEGACY_PREFERENCES,
                    Context.MODE_PRIVATE
            );
        }

        void writeAll(Map<String, String> values) throws Exception {
            if (values.isEmpty()) return;
            SecretKey secretKey = getOrCreateKey();
            SharedPreferences.Editor editor = securePreferences.edit();

            for (Map.Entry<String, String> entry : values.entrySet()) {
                Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
                cipher.init(Cipher.ENCRYPT_MODE, secretKey);
                cipher.updateAAD(entry.getKey().getBytes(StandardCharsets.UTF_8));
                byte[] encrypted = cipher.doFinal(
                        entry.getValue().getBytes(StandardCharsets.UTF_8)
                );

                editor.putString(
                        entry.getKey() + CIPHER_SUFFIX,
                        Base64.encodeToString(encrypted, Base64.NO_WRAP)
                );
                editor.putString(
                        entry.getKey() + IV_SUFFIX,
                        Base64.encodeToString(cipher.getIV(), Base64.NO_WRAP)
                );
            }

            if (!editor.commit()) {
                throw new IOException("Cannot persist encrypted credentials");
            }
        }

        Map<String, String> readAll(List<String> keys) throws Exception {
            migrateLegacyValues(keys);
            SecretKey secretKey = getExistingKey();
            Map<String, String> values = new HashMap<>();
            if (secretKey == null) return values;

            for (String key : keys) {
                String ciphertext = securePreferences.getString(
                        key + CIPHER_SUFFIX,
                        null
                );
                String iv = securePreferences.getString(key + IV_SUFFIX, null);
                if (ciphertext == null || iv == null) continue;

                Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
                cipher.init(
                        Cipher.DECRYPT_MODE,
                        secretKey,
                        new GCMParameterSpec(128, Base64.decode(iv, Base64.NO_WRAP))
                );
                cipher.updateAAD(key.getBytes(StandardCharsets.UTF_8));
                byte[] decrypted = cipher.doFinal(
                        Base64.decode(ciphertext, Base64.NO_WRAP)
                );
                values.put(key, new String(decrypted, StandardCharsets.UTF_8));
            }
            return values;
        }

        void deleteAll(List<String> keys) throws Exception {
            SharedPreferences.Editor secureEditor = securePreferences.edit();
            SharedPreferences.Editor legacyEditor = legacyPreferences.edit();
            for (String key : keys) {
                secureEditor.remove(key + CIPHER_SUFFIX);
                secureEditor.remove(key + IV_SUFFIX);
                legacyEditor.remove(LEGACY_PREFIX + key);
            }
            boolean secureRemoved = secureEditor.commit();
            boolean legacyRemoved = legacyEditor.commit();
            if (!secureRemoved || !legacyRemoved) {
                throw new IOException("Cannot remove credentials");
            }
            if (securePreferences.getAll().isEmpty()) {
                deleteKey();
            }
        }

        void resetEncryptedStorage() {
            securePreferences.edit().clear().commit();
            try {
                deleteKey();
            } catch (Exception ignored) {
                // Returning no credentials is safer than exposing corrupted data.
            }
        }

        private void migrateLegacyValues(List<String> keys) throws Exception {
            Map<String, String> legacyValues = new HashMap<>();
            Map<String, ?> existingValues = legacyPreferences.getAll();
            for (String key : keys) {
                Object value = existingValues.get(LEGACY_PREFIX + key);
                if (value instanceof String &&
                        !securePreferences.contains(key + CIPHER_SUFFIX)) {
                    legacyValues.put(key, (String) value);
                }
            }

            if (!legacyValues.isEmpty()) {
                writeAll(legacyValues);
            }

            SharedPreferences.Editor editor = legacyPreferences.edit();
            for (String key : keys) {
                if (securePreferences.contains(key + CIPHER_SUFFIX)) {
                    editor.remove(LEGACY_PREFIX + key);
                }
            }
            if (!editor.commit()) {
                throw new IOException("Cannot remove legacy credentials");
            }
        }

        private SecretKey getOrCreateKey() throws Exception {
            SecretKey existingKey = getExistingKey();
            if (existingKey != null) return existingKey;

            KeyGenerator keyGenerator = KeyGenerator.getInstance(
                    KeyProperties.KEY_ALGORITHM_AES,
                    ANDROID_KEY_STORE
            );
            keyGenerator.init(
                    new KeyGenParameterSpec.Builder(
                            KEY_ALIAS,
                            KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT
                    )
                            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                            .setKeySize(256)
                            .setRandomizedEncryptionRequired(true)
                            .build()
            );
            return keyGenerator.generateKey();
        }

        private SecretKey getExistingKey() throws Exception {
            KeyStore keyStore = KeyStore.getInstance(ANDROID_KEY_STORE);
            keyStore.load(null);
            return (SecretKey) keyStore.getKey(KEY_ALIAS, null);
        }

        private void deleteKey() throws Exception {
            KeyStore keyStore = KeyStore.getInstance(ANDROID_KEY_STORE);
            keyStore.load(null);
            if (keyStore.containsAlias(KEY_ALIAS)) {
                keyStore.deleteEntry(KEY_ALIAS);
            }
        }
    }
}
