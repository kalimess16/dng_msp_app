class IotDownloadFile {
  final String fileName;
  final String fileType;
  final String fileData;
  final int fileOrder;
  final int eofficeId;
  IotDownloadFile(
      {required this.fileName,
      required this.fileType,
      required this.fileData,
      required this.fileOrder,
      required this.eofficeId});
  factory IotDownloadFile.fromJson(Map<String, dynamic> json) {
    return IotDownloadFile(
        fileName: json['fileName'],
        fileType: json['fileType'],
        fileData: json['fileData'],
        fileOrder: json['fileOrder'] == null ? 0 : json['fileOrder'],
        eofficeId: json['eofficeId'] == null ? 0 : json['eofficeId']);
  }
}
