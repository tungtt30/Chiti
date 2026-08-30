// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Chiti';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get delete => 'Xóa';

  @override
  String get remove => 'Xóa';

  @override
  String get required => 'Bắt buộc';

  @override
  String get unknown => 'Không rõ';

  @override
  String errorLabel(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get languageSectionTitle => 'Ngôn ngữ';

  @override
  String get systemDefault => 'Theo hệ thống';

  @override
  String get englishLanguage => 'English';

  @override
  String get vietnameseLanguage => 'Tiếng Việt';

  @override
  String get myGroups => 'Nhóm của tôi';

  @override
  String get noGroupsYet => 'Chưa có nhóm nào';

  @override
  String get noGroupsHint => 'Nhấn + để tạo nhóm đầu tiên';

  @override
  String get newGroup => 'Nhóm mới';

  @override
  String get deleteGroupTitle => 'Xóa nhóm?';

  @override
  String deleteGroupContent(String groupName) {
    return 'Xóa \"$groupName\" và toàn bộ chi phí của nhóm?';
  }

  @override
  String get tabExpenses => 'Khoản chi';

  @override
  String get tabMembersAndNotes => 'Thành viên & Ghi chú';

  @override
  String get tabSummary => 'Tổng kết';

  @override
  String get editGroup => 'Sửa nhóm';

  @override
  String get groupNotFound => 'Không tìm thấy nhóm';

  @override
  String get noExpensesYet => 'Chưa có khoản chi nào';

  @override
  String get noExpensesHint => 'Nhấn + để thêm khoản chi';

  @override
  String expenseSubtitle(String paidBy, int joined, int total) {
    return '$paidBy đã trả · $joined/$total người tham gia';
  }

  @override
  String get createGroup => 'Tạo nhóm';

  @override
  String get groupName => 'Tên nhóm';

  @override
  String get location => 'Địa điểm';

  @override
  String get currency => 'Tiền tệ';

  @override
  String get startDate => 'Ngày bắt đầu';

  @override
  String get endDate => 'Ngày kết thúc';

  @override
  String get addExpense => 'Thêm khoản chi';

  @override
  String get editExpense => 'Sửa khoản chi';

  @override
  String get saveExpense => 'Lưu khoản chi';

  @override
  String get deleteExpense => 'Xóa khoản chi';

  @override
  String get deleteExpenseDialogTitle => 'Xóa khoản chi?';

  @override
  String deleteExpenseDialogContent(String title) {
    return 'Xóa \"$title\"? Hành động này không thể hoàn tác.';
  }

  @override
  String get expenseTitle => 'Tiêu đề';

  @override
  String get expenseTitleHint => 'Ăn tối, thuê sân cầu lông, tiền nhà, Grab…';

  @override
  String get amount => 'Số tiền';

  @override
  String get amountMustBePositive => 'Phải lớn hơn 0';

  @override
  String get category => 'Danh mục';

  @override
  String get whoPaid => 'Ai đã trả?';

  @override
  String get whoJoined => 'Ai tham gia?';

  @override
  String selectedOfMembers(int selected, int total) {
    return 'Đã chọn: $selected trên $total thành viên';
  }

  @override
  String eachApprox(String amount) {
    return ' (mỗi người ~ $amount)';
  }

  @override
  String get selectAll => 'Chọn tất cả';

  @override
  String get deselectAll => 'Bỏ chọn tất cả';

  @override
  String get liveSplitPreview => 'Xem trước mức chia';

  @override
  String eachPaysPreview(String amount) {
    return 'Mỗi người đóng: $amount';
  }

  @override
  String participantsCount(int count) {
    return '($count người tham gia)';
  }

  @override
  String payerSummary(String name, String amount, String suffix) {
    return '$name đã trả $amount$suffix';
  }

  @override
  String get notJoinedSuffix => ' (không tham gia)';

  @override
  String get amountGreaterThanZero => 'Số tiền phải lớn hơn 0';

  @override
  String get selectParticipantToSplit =>
      'Chọn ít nhất một người tham gia để chia';

  @override
  String get selectWhoPaid => 'Chọn người đã trả';

  @override
  String get addParticipantsFirst => 'Hãy thêm thành viên trước';

  @override
  String get joinPreviewText =>
      'Chưa chọn người tham gia. Hãy chọn những người tham gia khoản chi.';

  @override
  String get enterAmountPreview => 'Nhập số tiền để xem mức chia ngay.';

  @override
  String get membersAndNotesTitle => 'Thành viên & Ghi chú';

  @override
  String get addMember => 'Thêm thành viên';

  @override
  String get editMember => 'Sửa thành viên';

  @override
  String get noParticipantsYet => 'Chưa có thành viên';

  @override
  String get noParticipantsHint => 'Thêm nhóm để có thể chia chi phí';

  @override
  String get memberNotePlaceholder => 'Chưa có ghi chú';

  @override
  String get editAction => 'Sửa';

  @override
  String get removeAction => 'Xóa';

  @override
  String get removeParticipantTitle => 'Xóa thành viên?';

  @override
  String removeParticipantContent(String name) {
    return 'Xóa $name khỏi nhóm này?\nPhần chia và khoản chi của họ cũng sẽ bị xóa.';
  }

  @override
  String get qaAddExpense => 'Thêm chi tiêu nhanh';

  @override
  String get qaAddExpenseSubtitle => 'Thêm chi tiêu vào nhóm đang hoạt động';

  @override
  String get qaCreateGroup => 'Tạo nhóm mới';

  @override
  String get qaCreateGroupSubtitle => 'Tạo một nhóm mới';

  @override
  String get qaLatestSummary => 'Xem quyết toán gần nhất';

  @override
  String get qaLatestSummarySubtitle => 'Mở bảng quyết toán của nhóm gần nhất';

  @override
  String get editExpenseAction => 'Chỉnh sửa khoản chi';

  @override
  String get duplicateExpenseAction => 'Nhân bản khoản chi';

  @override
  String get deleteExpenseAction => 'Xóa khoản chi';

  @override
  String get setAsHost => 'Chỉ định làm Thủ quỹ';

  @override
  String get hostAlready => 'Đã là Thủ quỹ';

  @override
  String get viewExpenseHistory => 'Xem lịch sử chi tiêu';

  @override
  String get removeFromGroup => 'Xóa khỏi nhóm';

  @override
  String get nameField => 'Tên';

  @override
  String get contactOptional => 'Liên hệ (không bắt buộc)';

  @override
  String get contactHint => 'SĐT / email / handle';

  @override
  String get noteForGroupOptional => 'Ghi chú cho nhóm này (không bắt buộc)';

  @override
  String get noteHint => 'VD: Đặt cọc sớm, giảm giá chay…';

  @override
  String get avatarColor => 'Màu hình đại diện';

  @override
  String get expenseDetails => 'Chi tiết khoản chi';

  @override
  String get expenseNotFound => 'Không tìm thấy khoản chi';

  @override
  String joinedCount(int count) {
    return 'Tham gia ($count)';
  }

  @override
  String excludedCount(int count) {
    return 'Không tham gia ($count)';
  }

  @override
  String get everyoneJoined => 'Mọi người đều tham gia khoản chi này.';

  @override
  String get noShare => 'Không phải đóng';

  @override
  String splitEquallyPaidBy(String payer) {
    return 'Chia đều · $payer đã trả';
  }

  @override
  String get memberAuditTitle => 'Bảng đối soát thành viên';

  @override
  String get categoryAnalysisTitle => 'Phân tích danh mục';

  @override
  String get settlementPlanTitle => 'Kế hoạch thanh toán tối ưu';

  @override
  String get settlementModeTitle => 'Cài đặt thanh toán';

  @override
  String get settlementModeHostLabel => 'Thủ quỹ (Host)';

  @override
  String get settlementModeHostHint =>
      'Người nợ chuyển tiền cho thủ quỹ; thủ quỹ hoàn tiền cho người được trả';

  @override
  String get settlementModePeerToPeerLabel => 'Chuyển trực tiếp (peer-to-peer)';

  @override
  String get selectHost => 'Thủ quỹ';

  @override
  String get hostBadge => 'Thủ quỹ';

  @override
  String hostIs(String name) {
    return 'Thủ quỹ: $name';
  }

  @override
  String hostTransferSuffix(String host) {
    return '(qua thủ quỹ $host)';
  }

  @override
  String get recalculate => 'Tính / Cân đối lại';

  @override
  String get allSettledNoTransfer => 'Đã cân bằng, không cần chuyển khoản 🎉';

  @override
  String paidProgress(int count, int total) {
    return 'Đã thanh toán: $count/$total';
  }

  @override
  String get copyGroupReport => 'Sao chép báo cáo nhóm';

  @override
  String get shareSummary => 'Chia sẻ tổng kết';

  @override
  String get groupReportCopied => 'Đã sao chép báo cáo nhóm';

  @override
  String get captureReport => 'Chụp ảnh bảng kê';

  @override
  String get reportPreviewTitle => 'Xem trước ảnh';

  @override
  String get shareAction => 'Chia sẻ';

  @override
  String get saveToGallery => 'Lưu vào thư viện';

  @override
  String get savedToGallery => 'Đã lưu vào thư viện';

  @override
  String captureFailed(String error) {
    return 'Không thể tạo ảnh: $error';
  }

  @override
  String get reportGeneratedFooter => 'Tạo bởi Chiti';

  @override
  String shareReportText(String groupName) {
    return 'Báo cáo chi tiêu nhóm $groupName';
  }

  @override
  String get statsEmptyTitle => 'Chưa có khoản chi nào';

  @override
  String get statsEmptyHint =>
      'Thêm chi tiêu để xem bảng thống kê và kế hoạch thanh toán.';

  @override
  String get kpiTotalSpent => 'Tổng chi tiêu nhóm';

  @override
  String get kpiAveragePerPerson => 'TB / người';

  @override
  String get kpiExpenseCount => 'Số khoản chi';

  @override
  String get kpiLargestExpense => 'Khoản chi lớn nhất';

  @override
  String get auditMember => 'Thành viên';

  @override
  String get auditPaid => 'Đã ứng trước';

  @override
  String get auditOwes => 'Phải chịu';

  @override
  String get auditNetRule => 'Số dư ròng = Đã ứng trước − Phải chịu';

  @override
  String netReceiveBack(String amount) {
    return '+ Nhận lại $amount';
  }

  @override
  String netPayMore(String amount) {
    return '- Đóng thêm $amount';
  }

  @override
  String get netSettled => 'Đã cân bằng';

  @override
  String widgetNetPay(String amount) {
    return 'Phải đóng: $amount';
  }

  @override
  String widgetNetReceive(String amount) {
    return 'Được nhận: $amount';
  }

  @override
  String get noCategoryData => 'Chưa có dữ liệu danh mục.';

  @override
  String billsParticipation(int joined, int total) {
    return '$joined/$total khoản';
  }

  @override
  String transferLine(String from, String to, String amount) {
    return '$from chuyển cho $to: $amount';
  }

  @override
  String get transferStatusSettled => 'Đã thanh toán';

  @override
  String get transferStatusPending => 'Chưa thanh toán';

  @override
  String get copyText => 'Sao chép';

  @override
  String get copiedToClipboard => 'Đã sao chép vào clipboard';

  @override
  String reportTitle(String groupName) {
    return 'BÁO CÁO NHÓM \"$groupName\"';
  }

  @override
  String reportTotalAverage(String amount, String average) {
    return 'Tổng chi tiêu: $amount · Trung bình: $average/người';
  }

  @override
  String get reportMembersHeader => 'Thành viên:';

  @override
  String reportMemberLine(
    String name,
    String paid,
    String spent,
    int joined,
    int total,
    String net,
  ) {
    return '• $name — đã ứng: $paid · đã tiêu: $spent · tham gia $joined/$total khoản · $net';
  }

  @override
  String reportNetReceiveBack(String amount) {
    return 'nhận lại: +$amount';
  }

  @override
  String reportNetPayMore(String amount) {
    return 'đóng thêm: $amount';
  }

  @override
  String get reportNetSettled => 'đã cân bằng';

  @override
  String get reportCategoriesHeader => 'Danh mục chi tiêu:';

  @override
  String reportCategoryLine(
    String emoji,
    String label,
    String amount,
    int percent,
  ) {
    return '• $emoji $label: $amount ($percent%)';
  }

  @override
  String get reportSettlementsHeader => 'Thanh toán:';

  @override
  String get reportAllSettled => '• Đã cân bằng, không cần chuyển khoản 🎉';

  @override
  String reportSettlementLine(
    String from,
    String to,
    String amount,
    String paid,
  ) {
    return '• $from chuyển cho $to: $amount$paid';
  }

  @override
  String reportPaidProgress(int count, int total) {
    return '✅ Đã thanh toán: $count/$total';
  }

  @override
  String transferReportLine(String from, String to, String amount) {
    return '$from chuyển cho $to: $amount';
  }

  @override
  String get categorySports => 'Thể thao & Sân bãi';

  @override
  String get categoryDining => 'Ăn uống & Tiệc tùng';

  @override
  String get categoryCafe => 'Cafe & Trà đá';

  @override
  String get categoryTransport => 'Di chuyển';

  @override
  String get categoryHousing => 'Sinh hoạt & Tiền phòng';

  @override
  String get categoryEntertainment => 'Vui chơi & Giải trí';

  @override
  String get categoryShopping => 'Mua sắm chung';

  @override
  String get categoryOther => 'Khác';
}
