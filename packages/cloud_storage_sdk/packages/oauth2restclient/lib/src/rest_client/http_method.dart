enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head;

  bool get allowsBody =>
      this == post || this == put || this == patch || this == delete;
}
