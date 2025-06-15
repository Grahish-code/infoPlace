class ApiConstants {
  static const String baseUrl = "https://api.openweathermap.org/data/2.5/";
  static const String apiKey = "85327ec88518a7d0b2452e6e93508600";

  static const String baseUrl2 = "https://newsapi.org/v2";
  static const String apiKey2 = "175ba9d9d0b14b8887c862478ec1e098";

  static String topHeadlines(String category) =>
      "$baseUrl2/top-headlines?country=us&category=$category&apiKey=$apiKey2";



}
