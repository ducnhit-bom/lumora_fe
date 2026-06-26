import 'package:flutter/material.dart';

class LumoraLoadingState extends StatelessWidget {
  const LumoraLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class LumoraErrorState extends StatelessWidget {
  const LumoraErrorState({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

class LumoraEmptyState extends StatelessWidget {
  const LumoraEmptyState({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
