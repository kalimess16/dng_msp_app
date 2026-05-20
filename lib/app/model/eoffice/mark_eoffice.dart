class MarkEoffice {
  final int maso;
  final String tieude;
  final String tencoquan;
  final String ghichu;
  final String nguoigui;
  final String ngaygui;
  final int sotrang;
  final String tuvanthu;
  final int thutufile;

  MarkEoffice(this.maso, this.tieude, this.tencoquan, this.ghichu,
      this.nguoigui, this.ngaygui, this.sotrang, this.tuvanthu, this.thutufile);

  factory MarkEoffice.fromJson(Map<String, dynamic> json) {
    return MarkEoffice(
        json['maso'] ?? 0,
        json['tieude'] ?? '',
        json['tencoquan'] ?? '',
        json['ghichu'] ?? '',
        json['nguoigui'] ?? '',
        json['ngaygui'] ?? '',
        json['sotrang'] ?? 0,
        json['tuvanthu'] ?? 'N',
        json['thutufile'] ?? 0);
  }
}
