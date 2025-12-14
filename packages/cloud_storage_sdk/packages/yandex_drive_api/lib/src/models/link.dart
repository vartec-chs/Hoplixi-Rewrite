class Link {
  String? href;
  String? method;
  bool? templated;
  String? operationId;

  Link({this.href, this.method, this.templated, this.operationId});

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      href: json['href'],
      method: json['method'],
      templated: json['templated'],
      operationId: json['operation_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'href': href,
      'method': method,
      'templated': templated,
      'operation_id': operationId,
    };
  }
}
