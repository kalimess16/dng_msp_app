class IotManualReport {
  final String? id;
  final String? description;
  final String? dataType;
  final String? required;
  final Map<String, dynamic>? dropDownList;
  final String? value;

  IotManualReport(
      {this.id,
      this.description,
      this.dataType,
      this.required,
      this.dropDownList,
      this.value});
  factory IotManualReport.fromJson(Map<String, dynamic> json) {
    return IotManualReport(
        id: json['id'],
        description: json['description'],
        dataType: json['datatype'],
        required: json['required'],
        dropDownList: json['dropdownlist'] as Map<String, dynamic>?,
        value: json['defvalue']);
  }
}
