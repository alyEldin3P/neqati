import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading_indicator.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/offers/cubit/offers_cubit.dart';
import 'package:neqati/features/offers/cubit/offers_state.dart';
import 'package:neqati/features/offers/model/offer.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({Key? key}) : super(key: key);

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OffersCubit>().loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('العروض المتاحة', color: Colors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      body: BlocBuilder<OffersCubit, OffersState>(
        builder: (context, state) {
          if (state is OffersLoading) {
            return const Center(child: AppLoadingIndicator());
          } else if (state is OffersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(state.message, color: AppColors.alertRed),
                  SizedBox(height: AppDimensions.medium),
                  ElevatedButton(
                    onPressed: () => context.read<OffersCubit>().loadOffers(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepTeal),
                    child: const AppText('إعادة المحاولة', color: Colors.white),
                  ),
                ],
              ),
            );
          } else if (state is OffersLoaded) {
            final offers = state.offers;
            if (offers.isEmpty) {
              return Center(child: AppText('لا توجد عروض متاحة حالياً', color: AppColors.deepTeal));
            }
            return ListView.builder(
              padding: EdgeInsets.all(AppDimensions.medium),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                return _buildOfferCard(offers[index]);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOfferCard(Offer offer) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.medium),
      child: AppContainer(
        padding: EdgeInsets.all(AppDimensions.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offer.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.small),
                child: Image.network(
                  offer.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: AppColors.lightTeal,
                      child: Icon(Icons.image_not_supported, color: AppColors.deepTeal, size: 50),
                    );
                  },
                ),
              ),
            SizedBox(height: AppDimensions.medium),
            AppText.subtitle(offer.title, fontWeight: FontWeight.bold, color: AppColors.deepTeal),
            SizedBox(height: AppDimensions.small),
            AppText(offer.description),
            SizedBox(height: AppDimensions.medium),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.deepTeal),
                SizedBox(width: AppDimensions.tiny),
                AppText('ينتهي في: ${_formatDate(offer.endDate)}', isSmall: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
