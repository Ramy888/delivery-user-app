import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:provider/provider.dart';
import 'dart:developer' as dev;
import '../CustomWidgets/customized_text.dart';
import '../CustomWidgets/felsaree3_service_card.dart';
import '../Notifiers/homepage_address_notifier.dart';
import '../Utils/shared_prefs.dart';
import '../main.dart';
import 'HomePageBranched/map_screen.dart';
import 'new_request.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String TAG = 'HomePage';
  double? _currentLat;
  double? _currentLong;
  String? country, government, city, street;

  @override
  void initState() {
    super.initState();
    _checkAndInitializeLocation();
  }

  Future<void> _checkAndInitializeLocation() async {
    if((await SharedPreferenceHelper().getAddress())!.isEmpty) {
      await _getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // _buildAppBar(),
          SliverToBoxAdapter(child: _buildLocationBar()),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSaree3Item(context),
                  const SizedBox(height: 24),
                  _buildQuickServices(),
                  const SizedBox(height: 24),
                  _buildInviteCard(),
                  const SizedBox(height: 24),
                  _buildPopularServices(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      backgroundColor: Colors.white,
      title: Image.asset(
        "assets/images/logo.png",
        height: 32,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: Colors.grey[800],
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildLocationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on,
              color: primaryColor.withOpacity(0.8), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: "Deliver to",
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                Consumer<AddressProvider>(
                  builder: (context, addressProvider, child) {
                    String address = addressProvider.strAddress;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MapScreen()),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              text: address.isEmpty ? 'Loading...' : address,
                              color: primaryColor,
                              fontSize: 13,
                              maxLines: 1,
                              overFlow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServices() {
    final List<ServiceItem> quickServices = [
      ServiceItem(Icons.store, "SuperMarket", Colors.green),
      ServiceItem(Icons.local_pharmacy, "Pharmacy", Colors.red),
      ServiceItem(Icons.bakery_dining, "Bakery", Colors.orange),
      ServiceItem(Icons.local_gas_station, "Gas", Colors.purple),
      ServiceItem(Icons.room_service, "Meat & Chickens", Colors.brown),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Services",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: quickServices.length,
          itemBuilder: (context, index) {
            return _buildServiceItem(
              quickServices[index].icon,
              quickServices[index].label,
              quickServices[index].color,
            );
          },
        ),
      ],
    );
  }

  Widget _buildInviteCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Invite Friends",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Get free delivery on your next order!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Invite Now",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Popular Services",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildServiceItem(Icons.store, "SuperMarket", Colors.green),
            _buildServiceItem(Icons.local_pharmacy, "Pharmacy", Colors.red),
            _buildServiceItem(Icons.bakery_dining, "Bakery", Colors.orange),
            _buildServiceItem(Icons.local_gas_station, "Gas", Colors.purple),
            _buildServiceItem(Icons.set_meal, "Fish", Colors.blue),
            _buildServiceItem(Icons.fastfood, "Food", Colors.amber),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewStandardOrderPage(requestType: label),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaree3Item(BuildContext context) {
    return ServiceCard(
      icon: Icons.list_alt,
      label: "List of Items",
      color: Colors.blue[700]!,
      explanation:
          "Upload a photo of your shopping list and we'll deliver all items to your doorstep. Perfect for grocery shopping and bulk orders!",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewStandardOrderPage(
              requestType: "List of Items",
            ),
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    geolocator.LocationPermission permission;

    permission = await geolocator.Geolocator.checkPermission();
    dev.log(TAG, error: 'Permission: $permission');

    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();

      if (permission == geolocator.LocationPermission.denied) {
        // Permissions are denied, show a dialog with more information.
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("Location Permission"),
            content: Text(
                "It's important to grant location permission to be used in delivery."),
            actions: <Widget>[
              ElevatedButton(
                child: Text('OK'),
                onPressed: () async {
                  Navigator.of(context).pop(); // Dismiss the dialog
                  // Request permission again
                  await geolocator.Geolocator.requestPermission();
                  // Recursive call to check the new permission status and proceed accordingly.
                  await _getCurrentLocation();
                },
              ),
            ],
          ),
        );
        return;
      }
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      // Permissions are denied forever, show a dialog that directs them to the settings page.
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("Location Permission"),
          content: Text(
              "Location permissions are permanently denied, please open settings and grant location permission."),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Settings'),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss the dialog
                await AppSettings.openAppSettings();
                // Request permission again
                await geolocator.Geolocator.requestPermission();
                // Recursive call to check the new permission status and proceed accordingly.
                await _getCurrentLocation();
              },
            ),
          ],
        ),
      );
      return;
    }
    // Test if location services are enabled.
    serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    dev.log(TAG, error: 'ServiceEnabled: $serviceEnabled');
    if (!serviceEnabled) {
      geolocator.Geolocator.openLocationSettings();
    }

    // When we reach here, permissions are granted and location services are enabled.
    geolocator.Position position =
        await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high);
    // setState or any other method to handle the obtained position.
    setState(() {
      _currentLat = position.latitude;
      _currentLong = position.longitude;
    });

    // SharedPreferenceHelper().saveLatLng(_currentLat!, _currentLong!);

    _getAddressFromLatLong(position.latitude, position.longitude);

    // dev.log(TAG, error: 'CurrentLocation: $_currentLat, $_currentLong');
  }

  Future<void> _getAddressFromLatLong(double lat, double long) async {
    List<geocoding.Placemark> placemarks =
        await geocoding.placemarkFromCoordinates(lat, long);
    if (placemarks.isNotEmpty) {
      geocoding.Placemark place = placemarks.first;
      setState(() {
        country = place.country;
        government = place.administrativeArea;
        city = place.locality;
        street = place.street;
      });

      dev.log(TAG, error: 'country: $country || city $city');

      if (street!.isNotEmpty) {
        SharedPreferenceHelper().saveAddress('${street}, ${government}');
        Provider.of<AddressProvider>(context, listen: false)
            .updateAddressStr('${street}, ${government}');
      } else {
        SharedPreferenceHelper().saveAddress('${city}, ${government}');
        Provider.of<AddressProvider>(context, listen: false)
            .updateAddressStr('${street}, ${government}');
      }
    }
  }
}

class ServiceItem {
  final IconData icon;
  final String label;
  final Color color;

  ServiceItem(this.icon, this.label, this.color);
}
