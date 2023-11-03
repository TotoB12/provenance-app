import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

const Color mainColor = Color.fromARGB(255, 245, 245, 245);
const Color accentColor = Color(0xFF262626); // RGB(38, 38, 38)
const String codebar = '8000500037560'; //Kinder Bueno
// const String codebar = '8002270014901'; //S. Pellegrino

void main() {
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'Provenance');

  OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
    OpenFoodFactsLanguage.ENGLISH
  ];

  OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.USA;

  runApp(const MyApp());
}

String getEcoScoreMessage(String grade) {
  switch (grade.toUpperCase()) {
    case 'A':
      return 'Very low environmental impact';
    case 'B':
      return 'Low environmental impact';
    case 'C':
      return 'Moderate environmental impact';
    case 'D':
      return 'High environmental impact';
    case 'E':
      return 'Very high environmental impact';
    default:
      return 'Unknown environmental impact';
  }
}

String getNutriScoreMessage(String grade) {
  switch (grade.toUpperCase()) {
    case 'A':
      return 'Very good nutritional quality';
    case 'B':
      return 'Good nutritional quality';
    case 'C':
      return 'Average nutritional quality';
    case 'D':
      return 'Poor nutritional quality';
    case 'E':
      return 'Bad nutritional quality';
    default:
      return 'Unknown nutritional quality';
  }
}

String getNovaGroupMessage(String group) {
  switch (group) {
    case '1':
      return 'Unprocessed or minimally processed food';
    case '2':
      return 'Processed culinary ingredients';
    case '3':
      return 'Processed foods';
    case '4':
      return 'Ultra-processed product';
    default:
      return 'Food processing level unkown';
  }
}

String cleanIngredientsText(String text) {
  if (text.endsWith(',')) {
    return text.substring(0, text.length - 1).trim();
  } else if (text.endsWith('.')) {
    return text.substring(0, text.length - 1).trim();
  }
  return text;
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ProductPage(
              product: product,
            ),
          ),
        );
      },
      child: Column(
        children: <Widget>[
          // Center(
          //   child: Container(
          //     height: 0.4,
          //     width: MediaQuery.of(context).size.width * 0.9,
          //     color: Colors.black,
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: mainColor,
              elevation: 0.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  if (product.imageFrontSmallUrl != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: MediaQuery.of(context).size.width * 0.2,
                        child: Image.network(product.imageFrontSmallUrl!,
                            fit: BoxFit.contain),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: MediaQuery.of(context).size.width * 0.2,
                        child: const Icon(Icons.shopping_cart, size: 50),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ListTile(
                          title: Text(
                            product.productName ?? 'Unknown Product',
                            style: const TextStyle(
                              fontSize: 22,
                              fontFamily: 'Poly',
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (product.nutriscore != null &&
                                  product.nutriscore != 'not-applicable')
                                // Expanded(
                                SvgPicture.asset(
                                    'assets/images/nutriscore-${product.nutriscore}.svg',
                                    height: 50)
                              // )
                              else
                                // Expanded(
                                SvgPicture.asset(
                                    'assets/images/nutriscore-unknown.svg',
                                    height: 50),
                              // ),
                              const SizedBox(width: 10),
                              if (product.ecoscoreGrade != null &&
                                  product.ecoscoreGrade != 'not-applicable' &&
                                  product.ecoscoreGrade != 'unknown')
                                // Expanded(
                                SvgPicture.asset(
                                    'assets/images/ecoscore-${product.ecoscoreGrade}.svg',
                                    height: 50)
                              // )
                              else
                                // Expanded(
                                SvgPicture.asset(
                                    'assets/images/ecoscore-unknown.svg',
                                    height: 50),
                              // ),
                              const SizedBox(width: 10),
                              if (product.novaGroup != null &&
                                  product.novaGroup.toString() !=
                                      'not-applicable')
                                // Expanded(
                                SvgPicture.asset(
                                    'assets/images/nova-group-${product.novaGroup}.svg',
                                    height: 50)
                              // )
                              else
                                // Expanded(
                                SvgPicture.asset(
                                    'assets/images/nova-group-unknown.svg',
                                    height: 50)
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provenance',
      theme: ThemeData(
        primaryColor: accentColor,
        colorScheme: ThemeData().colorScheme.copyWith(primary: accentColor),
      ),
      home: const MyHomePage(title: 'Provenance'),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: Center(
        child: Text('Settings Page'),
      ),
    );
  }
}

class ProductPage extends StatelessWidget {
  final Product product;

  const ProductPage({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: mainColor,
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              product.productName ?? 'Unknown Product',
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'Poly',
              ),
              // maxLines: 2,
              // overflow: TextOverflow.ellipsis,
            ),
            automaticallyImplyLeading: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (product.imageFrontUrl != null)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    constraints: const BoxConstraints(
                      maxHeight: 200.0,
                    ),
                    child: Image.network(
                      product.imageFrontUrl!,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (product.imageFrontUrl == null) const SizedBox(height: 10),
                if (product.brands != null && product.brands!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                    child: _buildSubtitleText(
                      'Brand${product.brands.toString().split(',').length > 1 ? 's' : ''}: ',
                      product.brands ?? 'Unknown',
                    ),
                  ),
                if (product.origins != null && product.origins!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                    child: _buildSubtitleText(
                      'Origin of ingredients: ',
                      product.origins!.replaceAll(RegExp(r',(?!\s)'), ', '),
                    ),
                  ),

                if (product.manufacturingPlaces != null &&
                    product.manufacturingPlaces!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                    child: _buildSubtitleText(
                      'Manufacturing or processing place: ',
                      product.manufacturingPlaces ?? 'Unknown',
                    ),
                  ),
                if (product.quantity != null && product.quantity!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                    child: _buildSubtitleText(
                      'Quantity: ',
                      product.quantity ?? 'Unknown',
                    ),
                  ),
                if (product.servingSize != null &&
                    product.servingSize!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                    child: _buildSubtitleText(
                      'Serving size: ',
                      product.servingSize ?? 'Unknown',
                    ),
                  ),
                // if (product.nutriments != null)
                //   Padding(
                //     padding: const EdgeInsets.only(
                //         right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                //     child: _buildSubtitleText(
                //       'Nutrition facts: ',
                //       product.nutriments!.toJson().toString() ?? 'Unknown',
                //     ),
                //   ),
                if (product.ingredientsAnalysisTags != null)
                  _buildLabelsSubtitle(product.ingredientsAnalysisTags!),
                _buildScoreCard(
                  context: context,
                  dataValue: product.nutriscore,
                  assetPrefix: 'nutriscore',
                  description:
                      getNutriScoreMessage(product.nutriscore ?? 'Unknown'),
                ),
                _buildScoreCard(
                  context: context,
                  dataValue: product.ecoscoreGrade,
                  assetPrefix: 'ecoscore',
                  description:
                      getEcoScoreMessage(product.ecoscoreGrade ?? 'Unknown'),
                ),
                if (product.ingredientsText?.isNotEmpty ?? false)
                  _buildIngredientsCard(
                      context, product.ingredientsText!, product.ingredients),
                if (product.allergens != null &&
                    product.allergens!.names.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                    child: _buildBigSubtitleText(
                      'Allergens: ',
                      product.allergens!.names,
                    ),
                  ),
                if (product.tracesTags != null &&
                    product.tracesTags!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                    child: _buildBigSubtitleText(
                      'Traces: ',
                      product.tracesTags!,
                    ),
                  ),
                // if (product.tracesTags != null &&
                //     product.tracesTags!.isNotEmpty)
                //   Padding(
                //     padding: const EdgeInsets.only(
                //         right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                //     child: _buildSubtitleText(
                //       'Traces: ',
                //       product.tracesTags!.length.toString() ?? 'Unknown',
                //     ),
                //   ),
                _buildScoreCard(
                  context: context,
                  dataValue: product.novaGroup.toString(),
                  assetPrefix: 'nova-group',
                  description:
                      getNovaGroupMessage(product.novaGroup.toString()),
                ),
                if (product.nutriments != null)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                    child: _buildSubtitleText(
                      'Tables: ',
                      product.nutriments!.toJson().toString() ?? 'Unknown',
                    ),
                  ),
                if (product.nutriments != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: _createNutritionalDataTable(
                        product.nutriments, context),
                  ),
                const SizedBox(height: 12),
                if (product.barcode != null && product.barcode!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
                    child: _buildSubtitleText(
                      'Barcode: ',
                      product.barcode ?? 'Unknown',
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitleText(String leadingText, String trailingText,
      [Color textColor = Colors.black]) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: leadingText,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Poly',
              fontWeight: FontWeight.bold,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
          TextSpan(
            text: trailingText,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poly',
              fontWeight: FontWeight.w500,
              color: textColor, // Use the passed or default color
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildVeganVegetarianLabel(BuildContext context, List<String> labels) {
  //   bool isVegetarian = labels.contains('en:vegetarian');
  //   bool isVegan = labels.contains('en:vegan');
  //
  //   return Column(
  //     children: [
  //       if (isVegetarian)
  //         _buildLabelCard(
  //           context: context,
  //           svgAsset: 'assets/images/vegetarian.svg',
  //           label: 'Vegetarian',
  //         ),
  //       if (isVegan)
  //         _buildLabelCard(
  //           context: context,
  //           svgAsset: 'assets/images/vegan.svg',
  //           label: 'Vegan',
  //         ),
  //     ],
  //   );
  // }

  // Widget _buildLabelCard(
  //     {required BuildContext context,
  //     required String svgAsset,
  //     required String label}) {
  //   return Card(
  //     // margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  //     color: mainColor,
  //     elevation: 0.0,
  //     child: Row(
  //       children: [
  //         Container(
  //           width: MediaQuery.of(context).size.width * 0.3,
  //           height: 67,
  //           padding: const EdgeInsets.all(4.0),
  //           child: SvgPicture.asset(svgAsset,
  //               color: Colors.green, fit: BoxFit.contain),
  //         ),
  //         const SizedBox(width: 16.0),
  //         Expanded(
  //           child: Text(
  //             label,
  //             style: const TextStyle(
  //               fontSize: 20,
  //               fontFamily: 'Poly',
  //               fontWeight: FontWeight.w500,
  //               color: Colors.green,
  //               decoration: TextDecoration.none,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  String _getProductLabels(IngredientsAnalysisTags tags) {
    List<String> labels = [];

    switch (tags.vegetarianStatus) {
      case VegetarianStatus.VEGETARIAN:
        labels.add("Vegetarian");
        break;
      case VegetarianStatus.NON_VEGETARIAN:
        labels.add("Non-Vegetarian");
        break;
      default:
        break;
    }

    switch (tags.veganStatus) {
      case VeganStatus.VEGAN:
        labels.add("Vegan");
        break;
      case VeganStatus.NON_VEGAN:
        labels.add("Non-Vegan");
        break;
      default:
        break;
    }

    switch (tags.palmOilFreeStatus) {
      case PalmOilFreeStatus.PALM_OIL_FREE:
        labels.add("Palm Oil Free");
        break;
      case PalmOilFreeStatus.PALM_OIL:
        labels.add("Contains Palm Oil");
        break;
      default:
        break;
    }

    return labels.join(", ");
  }

  Widget _buildLabelsSubtitle(IngredientsAnalysisTags tags) {
    String labels = _getProductLabels(tags);
    Color textColor = Colors.black;

    if (labels.contains("Non-Vegetarian") ||
        labels.contains("Non-Vegan") ||
        labels.contains("Contains Palm Oil")) {
      textColor = Colors.red;
    } else if (labels.contains("Vegetarian") ||
        labels.contains("Vegan") ||
        labels.contains("Palm Oil Free")) {
      textColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.only(
          right: 20.0, left: 20.00, bottom: 5.0, top: 5.0),
      child: _buildSubtitleText(
        'Labels: ',
        labels,
        textColor,
      ),
    );
  }

  Widget _buildScoreCard({
    required BuildContext context,
    required String? dataValue,
    required String assetPrefix,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: mainColor,
      elevation: 0.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.3,
              height: 67,
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(
                dataValue != null &&
                        dataValue != 'not-applicable' &&
                        dataValue != 'unknown' &&
                        dataValue != 'null'
                    ? 'assets/images/$assetPrefix-$dataValue.svg'
                    : 'assets/images/$assetPrefix-unknown.svg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Poly',
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsCard(BuildContext context, String ingredientsText,
      List<Ingredient>? ingredients) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      color: mainColor,
      elevation: 0.0,
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          colorScheme: ThemeData().colorScheme.copyWith(primary: Colors.black),
        ),
        child: ExpansionTile(
          title: Text(
            '${ingredients?.length ?? 0} ingredient${ingredients != null && ingredients.length > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poly',
              fontWeight: FontWeight.w500,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
          leading: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            alignment: Alignment.center, // Align icon to the center
            child: const Icon(
              // Icons.list,
              Icons.local_dining,
              color: Colors.black,
              size: 40,
            ),
          ),
          collapsedTextColor: Colors.black,
          textColor: Colors.black,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                cleanIngredientsText(ingredientsText),
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poly',
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatList(List<String> list) {
    return list.map((item) => capitalizeFirstLetter(item)).join(', ');
  }

  Widget _buildBigSubtitleText(String leadingText, List<String> trailingList,
      [Color textColor = Colors.black]) {
    String trailingText = formatList(trailingList);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: leadingText,
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Poly',
              fontWeight: FontWeight.bold,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
          TextSpan(
            text: trailingText,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Poly',
              fontWeight: FontWeight.w500,
              color: textColor,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String formatNutrientValue(double value) {
    if (value >= 1.0 || value == 0.0) {
      return value
          .toStringAsFixed(2)
          .replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
    } else if (value < 1.0 && value > 0.01) {
      return value.toStringAsFixed(2);
    } else {
      return (value * 1000)
          .toStringAsFixed(2)
          .replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");
    }
  }

  Widget _createNutritionalDataTable(
      Nutriments? nutriments, BuildContext context) {
    if (nutriments == null) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic> nutrientsMap = nutriments.toJson();

    // Add this condition to check if nutrientsMap is not empty
    if (nutrientsMap.isEmpty) {
      return const SizedBox.shrink();
    }

    List<String> nutrientNames =
        nutrientsMap.keys.where((key) => key.endsWith('_100g')).toList();

    // if (nutrientNames.contains('energy-kcal_100g') ||
    //     nutrientNames.contains('energy-kj_100g')) {
    //   nutrientNames.remove('energy-kcal_100g');
    //   nutrientNames.remove('energy-kj_100g');
    //   nutrientNames.add('energy_100g');
    // }

    nutrientNames = nutrientNames
        .map((name) => capitalizeFirstLetter(name.replaceAll('_100g', '')))
        .toList();

    List<DataRow> rows = nutrientNames.map((baseName) {
      return DataRow(cells: [
        DataCell(_styledText(baseName)),
        DataCell(_styledText(
            "${nutrientsMap['${baseName.toLowerCase()}_serving'] ?? 0.0}")),
        DataCell(_styledText(
            "${nutrientsMap['${baseName.toLowerCase()}_100g'] ?? 0.0}")),
      ]);
    }).toList();

    double tableWidth = MediaQuery.of(context).size.width - 32.0;

    return SizedBox(
      width: tableWidth,
      child: DataTable(
        columnSpacing: 16.0,
        columns: [
          DataColumn(
              label: _styledText('Nutrient',
                  fontWeight: FontWeight.bold, fontSize: 14.0)),
          DataColumn(
              label: _styledText('Per Serving',
                  fontWeight: FontWeight.bold, fontSize: 14.0),
              numeric: true),
          DataColumn(
              label: _styledText('Per 100g',
                  fontWeight: FontWeight.bold, fontSize: 14.0),
              numeric: true),
        ],
        rows: rows,
      ),
    );
  }

  Widget _styledText(String text,
      {FontWeight fontWeight = FontWeight.w500, double fontSize = 15.0}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'Poly',
        fontWeight: fontWeight,
        color: Colors.black,
        decoration: TextDecoration.none,
      ),
      overflow: TextOverflow.visible,
      maxLines: null,
    );
  }

  // Widget _constrainedText(String text) {
  //   return _styledText(text);
  // }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String barcode = '';
  Future<Product>? productFuture;
  int _selectedIndex = 1;
  bool isFlashOn = false;
  bool isCameraFlipped = false;
  bool isWelcomeScreen = true;
  int historyVersion = 0;
  bool isError = false;
  bool isDeleteConfirmationVisible = false;
  String searchQuery = '';
  Future<SearchResult>? searchResult;
  Timer? _debounce;
  Map<String, bool> dropdownValue = {
    'No Additives': false,
    'Vegan': false,
    'Vegetarian': false,
    'No Palm Oil': false,
  };
  SortOption currentSortOption = SortOption.POPULARITY;
  Map<SortOption, String> sortOptionText = {
    SortOption.POPULARITY: 'Popularity',
    SortOption.ECOSCORE: 'Ecoscore',
    SortOption.NUTRISCORE: 'Nutriscore',
  };
  bool isLoadingLong = false;
  Timer? loadingTimer;
  final SpinKitSpinningLines spinny = const SpinKitSpinningLines(
    color: accentColor,
    size: 40.0,
    lineWidth: 2.0,
  );
  ScrollController scrollController = ScrollController();
  String errorMessage =
      'Please try again. Sorry, but either this product is not in the database, or the scan was unsuccessful.';
  MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.upcA],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  void clearSearch() {
    setState(() {
      searchQuery = '';
      searchResult = null;
    });
  }

  Future<SearchResult> searchProducts(String query) async {
    setState(() {
      isLoadingLong = false;
    });

    List<Parameter> parameters = <Parameter>[
      SearchTerms(terms: [query]),
      const PageSize(size: 20),
      SortBy(option: currentSortOption),
    ];

    if (dropdownValue['No Additives'] == true) {
      parameters.add(const WithoutAdditives());
    }
    if (dropdownValue['Vegan'] == true) {
      parameters.add(
          const IngredientsAnalysisParameter(veganStatus: VeganStatus.VEGAN));
    }
    if (dropdownValue['Vegetarian'] == true) {
      parameters.add(const IngredientsAnalysisParameter(
          vegetarianStatus: VegetarianStatus.VEGETARIAN));
    }
    if (dropdownValue['No Palm Oil'] == true) {
      parameters.add(const IngredientsAnalysisParameter(
          palmOilFreeStatus: PalmOilFreeStatus.PALM_OIL_FREE));
    }

    ProductSearchQueryConfiguration configuration =
        ProductSearchQueryConfiguration(
      parametersList: parameters,
      version: ProductQueryVersion.v3,
    );

    return await OpenFoodAPIClient.searchProducts(
      const User(userId: '', password: ''),
      configuration,
    );
  }

  // PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Poly',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF262626),
        toolbarHeight: 47.0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          Center(
            child: Container(
              color: mainColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        _debounce =
                            Timer(const Duration(milliseconds: 500), () {
                          setState(() {
                            searchQuery = value;
                            searchResult = searchProducts(searchQuery);
                          });
                        });
                      },
                      decoration: const InputDecoration(
                        // labelText: "Search",
                        hintText: "Search for products",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(7.0)),
                        ),
                      ),
                    ),
                  ),
                  // Padding(
                  //   // padding: const EdgeInsets.all(8.0),
                  //   padding: const EdgeInsets.only(
                  //       left: 20.0, right: 8.0, top: 8.0, bottom: 10.0),
                  //   child:

                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poly',
                      color: Colors.black,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      // set spacing between the elements

                      children: [
                        // Padding(
                        //   padding: const EdgeInsets.all(4.0),
                        //   child:
                        PopupMenuButton<String>(
                          onSelected: (String value) {
                            setState(() {
                              dropdownValue[value] = !dropdownValue[value]!;
                              searchResult = searchProducts(searchQuery);
                            });
                          },
                          itemBuilder: (BuildContext context) {
                            return dropdownValue.keys.map((String value) {
                              return CheckedPopupMenuItem<String>(
                                value: value,
                                checked: dropdownValue[value]!,
                                child: Text(value),
                              );
                            }).toList();
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list),
                              // const SizedBox(width: 8),
                              Text(
                                'Filters (${dropdownValue.values.where((v) => v).length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Poly',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ),
                        // Padding(
                        //   padding: const EdgeInsets.all(4.0),
                        //   child:
                        Row(
                          children: [
                            const Text('Sort by: '),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<SortOption>(
                                value: currentSortOption,
                                icon: const Icon(Icons.arrow_downward),
                                onChanged: (SortOption? newValue) {
                                  setState(() {
                                    currentSortOption = newValue!;
                                    searchResult = searchProducts(searchQuery);
                                  });
                                },
                                items: [
                                  DropdownMenuItem<SortOption>(
                                    value: SortOption.POPULARITY,
                                    child: Text(
                                        sortOptionText[SortOption.POPULARITY]!,
                                        style: const TextStyle(
                                            fontFamily: 'Poly')),
                                  ),
                                  DropdownMenuItem<SortOption>(
                                    value: SortOption.ECOSCORE,
                                    child: Text(
                                        sortOptionText[SortOption.ECOSCORE]!,
                                        style: const TextStyle(
                                            fontFamily: 'Poly')),
                                  ),
                                  DropdownMenuItem<SortOption>(
                                    value: SortOption.NUTRISCORE,
                                    child: Text(
                                        sortOptionText[SortOption.NUTRISCORE]!,
                                        style: const TextStyle(
                                            fontFamily: 'Poly')),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // ),
                      ],
                    ),
                  ),
                  // ),
                  const SizedBox(
                    height: 8,
                  ),
                  Center(
                    child: Container(
                      height: 0.4,
                      width: MediaQuery.of(context).size.width * 0.9,
                      color: Colors.black,
                    ),
                  ),
                  FutureBuilder<SearchResult>(
                    future: searchResult,
                    builder: (context, snapshot) {
                      if (searchQuery.isEmpty) {
                        return Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.manage_search,
                                  size:
                                      MediaQuery.of(context).size.height * 0.15,
                                  color: Colors.black,
                                ),
                                const Text(
                                  'Search for\nany product.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontFamily: 'Poly',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        loadingTimer?.cancel();
                        loadingTimer = Timer(const Duration(seconds: 10), () {
                          setState(() {
                            isLoadingLong = true;
                          });
                        });
                        return Column(
                          children: [
                            const SizedBox(
                              height: 20,
                            ),
                            spinny,
                            if (isLoadingLong)
                              const Text(
                                  'This is taking longer than expected,\nplease be patient.'),
                          ],
                        );
                      } else if (snapshot.hasData &&
                          snapshot.data!.products != null) {
                        return Expanded(
                          child: CupertinoScrollbar(
                            controller: scrollController,
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: snapshot.data!.products!.length,
                              itemBuilder: (context, index) {
                                Product product =
                                    snapshot.data!.products![index];
                                return Column(
                                  children: <Widget>[
                                    Center(
                                      child: Container(
                                        height: 0.4,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        color: Colors.black,
                                      ),
                                    ),
                                    ProductCard(product: product),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      } else {
                        return const Text('No results found');
                      }
                    },
                  ),
                ],
              ),
            ),
          ), // Search page
          Visibility(
            visible: _selectedIndex == 1,
            child: Container(
              color: mainColor,
              child: Column(
                children: <Widget>[
                  Flexible(
                    child: Stack(
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.62,
                          child: MobileScanner(
                            controller: cameraController,
                            onDetect: (capture) async {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != this.barcode) {
                                  setState(() {
                                    this.barcode = barcode.rawValue ?? '';
                                    isError = false;
                                    productFuture =
                                        getProductInfo(this.barcode);
                                    isWelcomeScreen = false;
                                  });
                                  HapticFeedback.heavyImpact();
                                }
                              }
                            },
                          ),
                        ),
                        Positioned(
                          top: 10.0,
                          left: 10.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: mainColor.withOpacity(0.7),
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(7.0)),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.flip_camera_ios),
                              onPressed: () {
                                cameraController.switchCamera();
                                HapticFeedback.lightImpact();
                                setState(() {
                                  isFlashOn = false;
                                  isCameraFlipped = !isCameraFlipped;
                                });
                              },
                            ),
                          ),
                        ),
                        // Positioned(
                        //   top: 10.0,
                        //   left: MediaQuery.of(context).size.width / 2 -
                        //       20, // Center the button
                        //   child: Container(
                        //     decoration: BoxDecoration(
                        //       color: mainColor.withOpacity(0.7),
                        //       shape: BoxShape.rectangle,
                        //       borderRadius:
                        //           const BorderRadius.all(Radius.circular(7.0)),
                        //     ),
                        //     child: IconButton(
                        //       icon: const Icon(Icons.input),
                        //       onPressed: () {
                        //         setState(() {
                        //           this.barcode = codebar;
                        //           productFuture = getProductInfo(this.barcode);
                        //           isWelcomeScreen = false;
                        //         });
                        //         HapticFeedback.heavyImpact();
                        //       },
                        //     ),
                        //   ),
                        // ),
                        Positioned(
                          top: 10.0,
                          right: 10.0,
                          child: isCameraFlipped
                              ? Container()
                              : Container(
                                  decoration: BoxDecoration(
                                    color: isFlashOn
                                        ? Colors.yellow.withOpacity(0.7)
                                        : mainColor.withOpacity(0.7),
                                    shape: BoxShape.rectangle,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(7.0)),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.flash_on),
                                    onPressed: () {
                                      cameraController.toggleTorch();
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        isFlashOn = !isFlashOn;
                                      });
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: isError
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 4.0, bottom: 17.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.network_check,
                                    size: MediaQuery.of(context).size.height *
                                        0.15,
                                    color: Colors.red,
                                  ),
                                  const Text(
                                    'There has been an error,\nplease try again.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'Poly',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : isWelcomeScreen
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Icon(
                                        Icons.camera_enhance,
                                        size:
                                            MediaQuery.of(context).size.height *
                                                0.15,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                          top: 10.0, bottom: 20.0),
                                      child: Text(
                                        'Scan product to\nget started.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'Poly',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : FutureBuilder<Product>(
                                future: productFuture,
                                builder: (BuildContext context,
                                    AsyncSnapshot<Product> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.2,
                                      child: Center(child: spinny),
                                    );
                                  } else {
                                    // if (snapshot.hasData) {
                                    return SingleChildScrollView(
                                      // padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: <Widget>[
                                          ProductCard(product: snapshot.data!),
                                        ],
                                      ),
                                    );
                                    // } else {
                                    //   return Text(errorMessage);
                                    // }
                                  }
                                },
                              ),
                  ),
                ],
              ),
            ),
          ), // Scan page
          Container(
            color: mainColor,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 5.0),
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'History',
                        style: TextStyle(
                            fontFamily: 'Poly',
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold),
                      ),
                      StatefulBuilder(
                        builder:
                            (BuildContext context, StateSetter dialogSetState) {
                          return isDeleteConfirmationVisible
                              ? Row(
                                  children: [
                                    const Text(
                                      'Clear all history?',
                                      style: TextStyle(
                                        fontFamily: 'Poly',
                                        fontSize: 17.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      child: const Text(
                                        'Yes',
                                        style: TextStyle(
                                          fontFamily: 'Poly',
                                          fontSize: 17.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () async {
                                        SharedPreferences prefs =
                                            await SharedPreferences
                                                .getInstance();
                                        await prefs.remove('history');
                                        setState(() {
                                          historyVersion++;
                                        });
                                        dialogSetState(() {
                                          isDeleteConfirmationVisible = false;
                                        });
                                      },
                                    ),
                                    TextButton(
                                      child: const Text(
                                        'No',
                                        style: TextStyle(
                                          fontFamily: 'Poly',
                                          fontSize: 17.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () {
                                        dialogSetState(() {
                                          isDeleteConfirmationVisible = false;
                                        });
                                      },
                                    ),
                                  ],
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    dialogSetState(() {
                                      isDeleteConfirmationVisible = true;
                                    });
                                  },
                                );
                        },
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    height: 0.4,
                    width: MediaQuery.of(context).size.width * 0.9,
                    color: Colors.black,
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<String>>(
                    future: SharedPreferences.getInstance()
                        .then((prefs) => prefs.getStringList('history') ?? []),
                    key: ValueKey(historyVersion),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: spinny);
                      } else {
                        if (snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.access_time,
                                  size:
                                      MediaQuery.of(context).size.height * 0.15,
                                  color: Colors.black,
                                ),
                                const Text(
                                  'Scan a product\nto get a history.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontFamily: 'Poly',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          List<Product> products = snapshot.data!
                              .map((e) => Product.fromJson(jsonDecode(e)))
                              .toList();
                          products = products.reversed.toList();

                          return CupertinoScrollbar(
                            child: ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                return Column(
                                  children: <Widget>[
                                    Center(
                                      child: Container(
                                        height: 0.4,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        color: Colors.black,
                                      ),
                                    ),
                                    ProductCard(product: products[index]),
                                  ],
                                );
                              },
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ), // History page
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))
        ]),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.black,
              iconSize: 37,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.grey[100]!,
              color: Colors.black,
              tabs: const [
                GButton(
                  icon: Icons.search,
                  text: 'Search',
                  textStyle: TextStyle(fontFamily: 'Poly'),
                ),
                GButton(
                  icon: Icons.camera_alt,
                  text: 'Scan',
                  textStyle: TextStyle(fontFamily: 'Poly'),
                ),
                GButton(
                  icon: Icons.history,
                  text: 'History',
                  textStyle: TextStyle(fontFamily: 'Poly'),
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                // _pageController.animateToPage(
                //   index,
                //   duration: const Duration(milliseconds: 400),
                //   curve: Curves.easeInOut,
                // );
                if (_selectedIndex == 1) {
                  cameraController.dispose();
                }
                if (index == 1) {
                  cameraController = MobileScannerController(
                    formats: [BarcodeFormat.ean13, BarcodeFormat.upcA],
                  );
                }
                setState(() {
                  _selectedIndex = index;
                  isFlashOn = false;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<Product> getProductInfo(String barcode) async {
    ProductQueryConfiguration config = ProductQueryConfiguration(
      barcode,
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: [
        ProductField.ALL,
      ],
      version: ProductQueryVersion.v3,
    );
    try {
      ProductResultV3 result = await OpenFoodAPIClient.getProductV3(config);
      if (result.product != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> history = prefs.getStringList('history') ?? [];
        history.add(jsonEncode(result.product!.toJson()));
        await prefs.setStringList('history', history);

        setState(() {
          isError = false;
        });

        return result.product!;
      } else {
        throw Exception('Product not found');
      }
    } catch (e) {
      debugPrint('Failed to get product info: $e');
      setState(() {
        isError = true;
      });
      throw Exception('Failed to get product info: $e');
    }
  }
}
