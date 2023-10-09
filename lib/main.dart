import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'Provenance');

  OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
    OpenFoodFactsLanguage.ENGLISH
  ];

  OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.USA;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provenance',
      theme: ThemeData(
        primaryColor: Color(0xFF262626), // RGB(38, 38, 38)
      ),
      home: MyHomePage(title: 'Provenance'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String barcode = '';
  Future<Product>? productFuture;
  int _selectedIndex = 1;
  bool isFlashOn = false;
  bool isCameraFlipped = false;
  bool isWelcomeScreen = true;
  String errorMessage =
      'Please try again. Sorry, but either this product is not in the database, or the scan was unsuccessful.';
  MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.upcA],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  // PageController _pageController = PageController();

  String getEcoScoreMessage(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 'Very good';
      case 'B':
        return 'Good';
      case 'C':
        return 'Mediocre';
      case 'D':
        return 'Bad';
      case 'E':
        return 'Very bad';
      default:
        return 'Unknown';
    }
  }

  String getNutriScoreMessage(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 'Very good';
      case 'B':
        return 'Good';
      case 'C':
        return 'Mediocre';
      case 'D':
        return 'Bad';
      case 'E':
        return 'Very bad';
      default:
        return 'Unknown';
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
        return 'Unknown';
    }
  }

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
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.search,
                  size: MediaQuery.of(context).size.height * 0.15,
                  color: Colors.black,
                ),
                const Text(
                  'Search for products\n above.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Poly',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ), // Search page
          Visibility(
            visible: _selectedIndex == 1,
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: MobileScanner(
                        controller: cameraController,
                        onDetect: (capture) async {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != this.barcode) {
                              setState(() {
                                this.barcode = barcode.rawValue ?? '';
                                productFuture = getProductInfo(this.barcode);
                                isWelcomeScreen = false;
                              });
                              HapticFeedback.heavyImpact();
                            }
                          }
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 10.0,
                      left: 10.0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
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
                    Positioned(
                      bottom: 10.0,
                      left: MediaQuery.of(context).size.width / 2 -
                          20, // Center the button
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.input),
                          onPressed: () {
                            setState(() {
                              this.barcode = '8000500037560';
                              productFuture = getProductInfo(this.barcode);
                              isWelcomeScreen = false;
                            });
                            HapticFeedback.heavyImpact();
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10.0,
                      right: 10.0,
                      child: isCameraFlipped
                          ? Container()
                          : Container(
                              decoration: BoxDecoration(
                                color: isFlashOn ? Colors.yellow : Colors.white,
                                shape: BoxShape.circle,
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
                Expanded(
                  child: isWelcomeScreen
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              // ClipRRect(
                              //   borderRadius: BorderRadius.circular(
                              //       20), // Adjust as needed
                              //   child: Image.asset(
                              //     'assets/icons/icon.png',
                              //     width: MediaQuery.of(context).size.width *
                              //         0.5, // 50% of screen width
                              //     height: MediaQuery.of(context).size.height *
                              //         0.2, // 20% of screen height
                              //     fit: BoxFit.cover,
                              //   ),
                              // ),
                              Icon(
                                Icons.camera_enhance,
                                size: MediaQuery.of(context).size.height *
                                    0.15, // 20% of screen height
                                color: Colors.black, // Set the color as needed
                              ),
                              const Text(
                                'Scan product to\n get started.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontFamily: 'Poly',
                                  fontWeight: FontWeight.w700,
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
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text(errorMessage);
                            } else {
                              if (snapshot.hasData) {
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              '${snapshot.data?.productName ?? 'Unknown Product'}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontFamily: 'Poly',
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () {
                                              setState(() {
                                                isWelcomeScreen = true;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      Card(
                                        child: ListTile(
                                          leading: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.2,
                                              child: snapshot.data
                                                          ?.imageFrontSmallUrl !=
                                                      null
                                                  ? Image.network(
                                                      snapshot
                                                          .data!.imageFrontUrl!,
                                                      fit: BoxFit.scaleDown,
                                                    )
                                                  : const Icon(
                                                      Icons.shopping_cart,
                                                      size: 24.0),
                                            ),
                                          ),
                                          title: Text(
                                            '${snapshot.data?.brands ?? 'Unknown'}, ${snapshot.data?.quantity ?? 'Unknown quantity'}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontFamily: 'Poly',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (snapshot.data?.nutriscore != null &&
                                          snapshot.data!.nutriscore !=
                                              'not-applicable')
                                        Card(
                                          child: ListTile(
                                            leading: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                                child: SvgPicture.asset(
                                                  'assets/images/nutriscore-${snapshot.data!.nutriscore}.svg',
                                                  fit: BoxFit.scaleDown,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              '${getNutriScoreMessage(snapshot.data?.nutriscore ?? 'Unknown')}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Poly',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (snapshot.data?.ingredientsText
                                              ?.isNotEmpty ??
                                          false)
                                        Card(
                                          child: ExpansionTile(
                                            title: Text(
                                              '${(snapshot.data!.ingredientsText ?? '').split(',').length} ingredient${(snapshot.data!.ingredientsText ?? '').split(',').length > 1 ? 's' : ''}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Poly',
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            leading: Icon(Icons.list),
                                            collapsedTextColor: Colors
                                                .black, // Color of the title text when the tile is collapsed
                                            textColor: Colors
                                                .blue, // Color of the title text when the tile is expanded
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  '${snapshot.data?.ingredientsText}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontFamily: 'Poly',
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (snapshot.data?.ecoscoreGrade !=
                                              null &&
                                          snapshot.data!.ecoscoreGrade !=
                                              'not-applicable' &&
                                          snapshot.data!.ecoscoreGrade !=
                                              'unknown')
                                        Card(
                                          child: ListTile(
                                            leading: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                                child: SvgPicture.asset(
                                                  'assets/images/ecoscore-${snapshot.data!.ecoscoreGrade}.svg',
                                                  fit: BoxFit.scaleDown,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              '${getEcoScoreMessage(snapshot.data?.ecoscoreGrade ?? 'Unknown')}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Poly',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (snapshot.data?.novaGroup != null &&
                                          snapshot.data!.novaGroup !=
                                              'not-applicable')
                                        Card(
                                          child: ListTile(
                                            leading: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.1,
                                                child: SvgPicture.asset(
                                                  'assets/images/nova-group-${snapshot.data!.novaGroup}.svg',
                                                  fit: BoxFit.scaleDown,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              '${getNovaGroupMessage(snapshot.data?.novaGroup.toString() ?? 'Unknown')}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontFamily: 'Poly',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              } else {
                                return Text(errorMessage);
                              }
                            }
                          },
                        ),
                ),
              ],
            ),
          ), // Scan page
          Container(
            color: Colors.white,
            child: FutureBuilder<List<String>>(
              future: SharedPreferences.getInstance()
                  .then((prefs) => prefs.getStringList('history') ?? []),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  List<Product> products = snapshot.data!
                      .map((e) => Product.fromJson(jsonDecode(e)))
                      .toList();
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      Product product = products[index];
                      return Card(
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              leading: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.2,
                                  child: product.imageFrontSmallUrl != null
                                      ? Image.network(product.imageFrontUrl!,
                                          fit: BoxFit.scaleDown)
                                      : const Icon(Icons.shopping_cart,
                                          size: 24.0),
                                ),
                              ),
                              title: Text(
                                '${product.productName ?? 'Unknown Product'}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'Poly',
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  if (product.nutriscore != null &&
                                      product.nutriscore != 'not-applicable')
                                    SvgPicture.asset(
                                        'assets/images/nutriscore-${product.nutriscore}.svg'),
                                  if (product.ecoscoreGrade != null &&
                                      product.ecoscoreGrade !=
                                          'not-applicable' &&
                                      product.ecoscoreGrade != 'unknown')
                                    SvgPicture.asset(
                                        'assets/images/ecoscore-${product.ecoscoreGrade}.svg'),
                                  if (product.novaGroup != null &&
                                      product.novaGroup != 'not-applicable')
                                    SvgPicture.asset(
                                        'assets/images/nova-group-${product.novaGroup}.svg'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
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
        // Save the product data
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> history = prefs.getStringList('history') ?? [];
        history.add(jsonEncode(result.product!.toJson()));
        await prefs.setStringList('history', history);

        return result.product!;
      } else {
        throw Exception('Product not found');
      }
    } catch (e) {
      debugPrint('Failed to get product info: $e');
      throw Exception('Failed to get product info: $e');
    }
  }
}
