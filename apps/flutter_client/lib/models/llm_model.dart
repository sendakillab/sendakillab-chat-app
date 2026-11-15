class LlmModel {
  const LlmModel({required this.name});
  final String name;

  factory LlmModel.fromJson(Map<String, dynamic> json) {
    return LlmModel(name: (json['name'] ?? json['model'] ?? '').toString());
  }
}
