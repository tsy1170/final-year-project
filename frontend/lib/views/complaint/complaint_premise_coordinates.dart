import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/location_view_model.dart';
import '../../viewmodels/complaint_view_model.dart';
import 'add_complaint_attachments.dart';
import '../widgets/common/animated_notification.dart';
import '../widgets/common/custom_button.dart';

class ComplaintPremiseCoordinatesView extends StatefulWidget {
  final double scale;

  const ComplaintPremiseCoordinatesView({super.key, required this.scale});

  @override
  State<ComplaintPremiseCoordinatesView> createState() => _ComplaintPremiseCoordinatesViewState();
}

class _ComplaintPremiseCoordinatesViewState extends State<ComplaintPremiseCoordinatesView> {
  GoogleMapController? _mapController;

  Future<void> _focusOnUserLocation() async {
    final locationVM = Provider.of<LocationViewModel>(context, listen: false);
    
    // If we don't have current position yet, try to initialize it
    if (locationVM.currentPosition == null) {
      await locationVM.initLocation();
    }

    if (locationVM.currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(locationVM.currentPosition!.latitude, locationVM.currentPosition!.longitude),
          15,
        ),
      );
    }
  }

  void _onLongPress(LatLng location, ComplaintViewModel viewModel) {
    viewModel.setLocation(location.latitude, location.longitude);
  }

  void _onMapCreated(GoogleMapController controller, ComplaintViewModel viewModel) {
    _mapController = controller;
    if (viewModel.latitude == null) {
      _focusOnUserLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplaintViewModel>(
      builder: (context, viewModel, child) {
        final selectedLocation = (viewModel.latitude != null && viewModel.longitude != null) 
            ? LatLng(viewModel.latitude!, viewModel.longitude!) 
            : null;

        return Scaffold(
          backgroundColor: const Color(0xFFFBF8F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBF8F5),
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: const Color(0xFF1A1D1F), size: 20 * widget.scale),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'PREMISE LOCATION',
              style: TextStyle(
                color: const Color(0xFF1A1D1F),
                fontSize: 15 * widget.scale,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) => _onMapCreated(controller, viewModel),
                      initialCameraPosition: CameraPosition(
                        target: selectedLocation ?? const LatLng(3.1390, 101.6869), // Default to KL
                        zoom: 12,
                      ),
                      onLongPress: (location) => _onLongPress(location, viewModel),
                      markers: selectedLocation != null ? {
                        Marker(
                          markerId: const MarkerId("selected_location"),
                          position: selectedLocation,
                        ),
                      } : {},
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                    Positioned(
                      top: 20 * widget.scale,
                      left: 10 * widget.scale,
                      right: 10 * widget.scale,
                      child: Container(
                        padding: EdgeInsets.all(10 * widget.scale),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8 * widget.scale),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "Long press on the map to place a marker at the premise location.",
                          style: TextStyle(
                            fontSize: 12 * widget.scale,
                            color: const Color(0xFF1A1D1F),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                    20 * widget.scale,
                    20 * widget.scale,
                    20 * widget.scale,
                    10 * widget.scale + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedLocation != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCoordItem("LATITUDE", selectedLocation.latitude.toStringAsFixed(10)),
                          _buildCoordItem("LONGITUDE", selectedLocation.longitude.toStringAsFixed(10)),
                        ],
                      ),
                      SizedBox(height: 20 * widget.scale),
                    ],
                    CustomButton(
                      label: "NEXT",
                      onTap: () {
                        if (selectedLocation == null) {
                          showTopNotification(context, "Please select a location on the map", false, widget.scale);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ComplaintAddAttachmentsView(scale: widget.scale),
                          ),
                        );
                      },
                      bg: const Color(0xFF1A1D1F),
                      text: Colors.white,
                      scale: widget.scale,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildCoordItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10 * widget.scale,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFB85A3A),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14 * widget.scale,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1D1F),
          ),
        ),
      ],
    );
  }
}
