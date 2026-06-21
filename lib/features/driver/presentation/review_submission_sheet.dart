import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import 'driver_providers.dart';

class ReviewSubmissionSheet extends ConsumerStatefulWidget {
  final String spotId;
  final String bookingId;
  
  const ReviewSubmissionSheet({
    super.key,
    required this.spotId,
    required this.bookingId,
  });

  @override
  ConsumerState<ReviewSubmissionSheet> createState() => _ReviewSubmissionSheetState();
}

class _ReviewSubmissionSheetState extends ConsumerState<ReviewSubmissionSheet> {
  final _reviewController = TextEditingController();
  int _rating = 5;
  bool _isLoading = false;

  void _submitReview() async {
    setState(() => _isLoading = true);
    try {
      final spotIdVal = int.tryParse(widget.spotId) ?? 0;
      final bookingIdVal = int.tryParse(widget.bookingId) ?? 0;
      
      final success = await ref.read(bookingControllerProvider.notifier).submitReview(
        spotIdVal,
        bookingIdVal,
        _rating,
        _reviewController.text,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: AppTheme.success));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit review.'), backgroundColor: AppTheme.error));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit review.'), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rate your experience', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Write a review...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitReview,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Review'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

void showReviewSheet(BuildContext context, String spotId, String bookingId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.bgPanel,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => ReviewSubmissionSheet(spotId: spotId, bookingId: bookingId),
  );
}
