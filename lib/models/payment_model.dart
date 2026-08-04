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
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return PaymentModel(
      id: parseId(json['id']),
      parentId: parseId(json['parentId'] ?? json['parent_id']),
      visitId: parseId(json['visit_id'] ?? json['visitId']),
      patientId: parseId(json['patient_id'] ?? json['patientId']),
      invoiceNo: json['invoice_no'] as String? ?? json['invoiceNo'] as String? ?? '',
      subtotal: parseDouble(json['subtotal']),
      discount: parseDouble(json['discount']),
      totalAmount: parseDouble(json['total_amount'] ?? json['totalAmount']),
      paidAmount: parseDouble(json['paid_amount'] ?? json['paidAmount']),
      pendingAmount: parseDouble(json['pending_amount'] ?? json['pendingAmount']),
      paymentMethod: json['payment_method'] as String? ?? json['paymentMethod'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? json['paymentStatus'] as String? ?? '',
      paymentDate: json['payment_date'] as String? ?? json['paymentDate'] as String? ?? '',
      remarks: json['remarks'] as String? ?? '',
      createdBy: parseId(json['created_by'] ?? json['createdBy']),
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? json['updatedAt'] as String? ?? '',
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
