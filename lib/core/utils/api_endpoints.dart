class ApiEndpoints {
  static const String baseUrl = 'http://10.0.2.2:8080';
  static _AuthEndpoints authEndpoints = _AuthEndpoints();
}

class _AuthEndpoints {
  final String loginEmail = '/signin';
  final String signup = '/signup';

  final String addUser = '/users';
  final String getUsers = '/users';
  final String deleteUser = '/users/deleteUser';
  final String updateUser = '/users/updateUser';


  final String getSuppliers = '/suppliers';
  final String postSuppliers = '/suppliers';
  final String deleteSupplier = '/suppliers';
  final String updateSupplier = '/suppliers';

  final String getProducts = '/products';
  final String addProduct = '/products/create';
  String deleteProduct(String productId) => '/products/$productId';
  final String getProductById = '/products/{id}';
  final String getDashboardData = '/products/dashboard';

  final String getCategories = '/categories';
  final String addCategory = '/categories/add';
  String getSubCategories(String categoryId) => '/categories/$categoryId/subcategories';
  String addSubCategory(String categoryId) => '/categories/$categoryId/subcategories';
  String addSubSubCategory(String subCategoryId) => '/subcategories/$subCategoryId/subcategories';
  String getSubSubCategories(String subCategoryId) => '/subcategories/$subCategoryId/subsubcategories';
}