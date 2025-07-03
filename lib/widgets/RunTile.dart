import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:run_to_sip_app/models/run_model.dart';
import 'dart:ui';

class RunTile extends StatelessWidget {
  final RunModel run;
  final VoidCallback onTap;

  const RunTile({
    Key? key,
    required this.run,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: run.image,
                    fit: BoxFit.cover,
                    memCacheWidth: 400, // Optimize memory usage
                    memCacheHeight: 200,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[400],
                      child: const Center(
                        child: Text(
                          "Image not available",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),

                // Blur layer over the image
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.6), // slight dark overlay for contrast
                    ),
                  ),
                ),

                // Text content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          Text(
                            '#${run.runNumber.toString()}',
                            style: const TextStyle(
                              fontSize: 25,
                              fontFamily: 'Montserrat',
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            run.date,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              run.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'RacingSansOne',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              run.description,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                                color: Colors.white70,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
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
      ),
    );
  }
}