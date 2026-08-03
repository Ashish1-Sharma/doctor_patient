/// Model representing payment and billing details.
class PaymentModel {
  final int id;
  final int parentId;
  final int visitId;
  final int patientId;
  final String invoiceNo;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String paymentDate;
  final String remarks;
  final int createdBy;
  final String createdAt;
  final String updatedAt;

  const PaymentModel({
    required this.id,
    required this.parentId,
    required this.visitId,
    required this.patientId,
    required this.invoiceNo,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentDate,
    required this.remarks,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int? ?? 0,
      parentId: json['parentId'] as int? ?? 0,
      visitId: json['visitId'] as int? ?? 0,
      patientId: json['patientId'] as int? ?? 0,
      invoiceNo: json['invoiceNo'] as String? ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? '',
      paymentDate: json['paymentDate'] as String? ?? '',
      remarks: json['remarks'] as String? ?? '',
      createdBy: json['createdBy'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'visitId': visitId,
      'patientId': patientId,
      'invoiceNo': invoiceNo,
      'subtotal': subtotal,
      'discount': discount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentDate': paymentDate,
      'remarks': remarks,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
