import 'package:flutter/material.dart';
import 'user.dart';

class Task {
  final int id;
  final String title;
  final String description;
  final String priority; // LOW, MEDIUM, HIGH
  final String status; // NEW, IN_PROGRESS, COMPLETED, CANCELLED
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? assignedTo;
  final List<User> assignees;
  final User? createdBy;
  final Vehicle? vehicle;
  final List<TaskFile> files;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    this.assignees = const [],
    this.createdBy,
    this.vehicle,
    this.files = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'NEW',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      assignedTo: json['assigned_user_details'] != null 
          ? User.fromJson(json['assigned_user_details']) : null,
      assignees: json['assignees_details'] != null 
          ? (json['assignees_details'] as List).map((e) => User.fromJson(e)).toList()
          : [],
      createdBy: json['created_by_details'] != null 
          ? User.fromJson(json['created_by_details']) : null,
      vehicle: json['vehicle_details'] != null 
          ? Vehicle.fromJson(json['vehicle_details']) : null,
      files: json['files'] != null 
          ? (json['files'] as List).map((e) => TaskFile.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get priorityText {
    switch (priority) {
      case 'LOW':
        return 'Низкий';
      case 'MEDIUM':
        return 'Средний';
      case 'HIGH':
        return 'Высокий';
      default:
        return 'Средний';
    }
  }

  String get statusText {
    switch (status) {
      case 'NEW':
        return 'К выполнению';
      case 'IN_PROGRESS':
        return 'В работе';
      case 'COMPLETED':
        return 'Выполнено';
      case 'CANCELLED':
        return 'Отменено';
      default:
        return 'К выполнению';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'LOW':
        return Colors.blue;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'NEW':
        return Colors.grey;
      case 'IN_PROGRESS':
        return Colors.amber;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'NEW':
        return Icons.radio_button_unchecked;
      case 'IN_PROGRESS':
        return Icons.access_time;
      case 'COMPLETED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }
}

class TaskFile {
  final int id;
  final String file;
  final String originalName;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;
  final User? uploadedBy;

  TaskFile({
    required this.id,
    required this.file,
    required this.originalName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    this.uploadedBy,
  });

  factory TaskFile.fromJson(Map<String, dynamic> json) {
    return TaskFile(
      id: json['id'] ?? 0,
      file: json['file'] ?? '',
      originalName: json['original_name'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: json['file_size'] ?? 0,
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? DateTime.now().toIso8601String()),
      uploadedBy: json['uploaded_by'] != null 
          ? User.fromJson(json['uploaded_by']) : null,
    );
  }

  bool get isImage {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return imageExtensions.any((ext) => originalName.toLowerCase().endsWith(ext));
  }

  String get fileSizeDisplay {
    if (fileSize < 1024) {
      return '$fileSize Б';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).round()} КБ';
    } else {
      return '${(fileSize / (1024 * 1024)).round()} МБ';
    }
  }
}

class Vehicle {
  final int id;
  final String brand;
  final String model;
  final String number;
  final String status;

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.number,
    required this.status,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      number: json['number'] ?? '',
      status: json['status'] ?? 'AVAILABLE',
    );
  }
} 
 
 
 
 