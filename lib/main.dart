import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  String errorMessage =
      'Please try again. Sorry, but either this product is not in the database, or the scan was unsuccessful.';
  MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.upcA],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

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
          Container(color: Colors.white), // Search page
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
                  child: FutureBuilder<Product>(
                    future: productFuture,
                    builder: (BuildContext context,
                        AsyncSnapshot<Product> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text(errorMessage);
                      } else {
                        if (snapshot.hasData) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  '${snapshot.data?.productName ?? 'Unknown Product'}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Poly',
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Card(
                                  child: ListTile(
                                    leading: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.2, // 20% of screen width
                                        child: snapshot.data?.imageFrontUrl !=
                                                null
                                            ? Image.network(
                                                snapshot.data!.imageFrontUrl!,
                                                fit: BoxFit.scaleDown,
                                              )
                                            : const Icon(Icons.shopping_cart,
                                                size: 24.0),
                                      ),
                                    ),
                                    title: Text(
                                      'Brands: ${snapshot.data?.brands ?? 'Unknown'}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontFamily: 'Poly',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                if (snapshot.data?.ecoscoreGrade != null &&
                                    snapshot.data!.ecoscoreGrade !=
                                        'not-applicable' &&
                                    snapshot.data!.ecoscoreGrade != 'unknown')
                                  Card(
                                    child: ListTile(
                                      leading: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4, // 40% of screen width
                                          child: SvgPicture.asset(
                                            'assets/images/ecoscore-${snapshot.data!.ecoscoreGrade}.svg',
                                            fit: BoxFit.scaleDown,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        'EcoScore: ${snapshot.data?.ecoscoreGrade ?? 'Unknown'}',
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
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4,
                                          child: SvgPicture.asset(
                                            'assets/images/nutriscore-${snapshot.data!.nutriscore}.svg',
                                            fit: BoxFit.scaleDown,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        'NutriScore: ${snapshot.data?.nutriscore ?? 'Unknown'}',
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
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.4, // 40% of screen width
                                          child: SvgPicture.asset(
                                            'assets/images/nova-group-${snapshot.data!.novaGroup}.svg',
                                            fit: BoxFit.scaleDown,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        'Nova Group: ${snapshot.data?.novaGroup ?? 'Unknown'}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontFamily: 'Poly',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Add more fields as needed
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
          Container(color: Colors.white), // History page
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
