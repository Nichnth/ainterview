import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/pin_input_field.dart';
import '../widgets/custom_toggle.dart';
import '../widgets/custom_checkbox.dart';
import '../widgets/custom_radio_button.dart';
import '../widgets/date_time_picker.dart';
import '../widgets/bottom_sheet_selector.dart';
import '../widgets/custom_search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();
  final _searchController = TextEditingController();

  String? _selectedDropdownValue = 'Opsi 1';
  bool _toggleValue = true;
  bool _checkboxValue = false;
  String? _radioGroupValue = 'Pria';

  DateTime? _selectedDate;
  String _selectedPaymentMethod = 'Transfer Bank Mandiri';

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.main)),
          const Divider(thickness: 1, color: AppColors.border),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Katalog Komponen UI', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildSectionTitle('1. Custom Button'),
            CustomButton(text: 'Tombol Normal', onPressed: () {}),
            AppSizes.vSpaceSmall,
            const CustomButton(text: 'Tombol Disabled', onPressed: null),

            _buildSectionTitle('2. Custom Text Field'),
            CustomTextField(
              label: 'Nama Lengkap (Normal)',
              hintText: 'Masukkan nama Anda',
              controller: _textController,
            ),
            AppSizes.vSpaceSmall,
            CustomTextField(
              label: 'Email (Disabled)',
              hintText: 'email@domain.com',
              controller: _textController,
              enabled: false,
            ),
            AppSizes.vSpaceSmall,
            CustomTextField(
              label: 'Kata Sandi (Error State)',
              hintText: 'Masukkan kata sandi',
              controller: _textController,
              obscureText: true,
              errorText: 'Kata sandi minimal harus 8 karakter',
            ),

            _buildSectionTitle('3. Custom Dropdown'),
            CustomDropdown<String>(
              label: 'Pilih Jurusan (Normal)',
              hintText: 'Pilih salah satu',
              value: _selectedDropdownValue,
              items: const [
                DropdownMenuItem(value: 'Opsi 1', child: Text('Teknik Informatika')),
                DropdownMenuItem(value: 'Opsi 2', child: Text('Sistem Informasi')),
              ],
              onChanged: (val) => setState(() => _selectedDropdownValue = val),
            ),
            AppSizes.vSpaceSmall,
            const CustomDropdown<String>(
              label: 'Pilih Kota (Disabled)',
              hintText: 'Data tidak tersedia',
              value: null,
              items: null,
              onChanged: null,
            ),

            _buildSectionTitle('4. Pin Input Field (6 Kotak)'),
            Text('Status Normal:', style: AppTextStyles.caption),
            AppSizes.vSpaceSmall,
            PinInputField(onCompleted: (pin) => debugPrint('PIN: $pin')),
            AppSizes.vSpaceSmall,
            Text('Status Error:', style: AppTextStyles.caption),
            AppSizes.vSpaceSmall,
            PinInputField(onCompleted: (_) {}, hasError: true),

            _buildSectionTitle('5. Custom Toggle'),
            CustomToggle(
              label: 'Notifikasi Aplikasi',
              value: _toggleValue,
              onChanged: (val) => setState(() => _toggleValue = val),
            ),
            CustomToggle(
              label: 'Mode Malam (Disabled)',
              value: false,
              onChanged: null,
            ),

            _buildSectionTitle('6. Custom Checkbox'),
            CustomCheckbox(
              labelWidget: Text('Saya menyetujui Syarat dan Ketentuan.', style: AppTextStyles.bodyMedium),
              value: _checkboxValue,
              onChanged: (val) => setState(() => _checkboxValue = val ?? false),
            ),
            CustomCheckbox(
              labelWidget: Text('Ingat Saya di perangkat ini (Disabled)', style: AppTextStyles.bodyMedium),
              value: true,
              onChanged: null,
            ),
            CustomCheckbox(
              labelWidget: Text('Wajib dicentang (Error State)', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
              value: false,
              onChanged: (val) {},
              hasError: true,
            ),

            _buildSectionTitle('7. Custom Radio Button'),
            Row(
              children: [
                Expanded(
                  child: CustomRadioButton<String>(
                    label: 'Pria',
                    value: 'Pria',
                    groupValue: _radioGroupValue,
                    onChanged: (val) => setState(() => _radioGroupValue = val),
                  ),
                ),
                Expanded(
                  child: CustomRadioButton<String>(
                    label: 'Wanita',
                    value: 'Wanita',
                    groupValue: _radioGroupValue,
                    onChanged: (val) => setState(() => _radioGroupValue = val),
                  ),
                ),
              ],
            ),
            const CustomRadioButton<String>(
              label: 'Opsi Tidak Tersedia (Disabled)',
              value: 'Lainnya',
              groupValue: 'Pria',
              onChanged: null,
            ),

            _buildSectionTitle('8. Date Time Picker'),
            CustomDateTimePicker(
              label: 'Tanggal Lahir (Normal)',
              valueText: _selectedDate != null
                  ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                  : 'Pilih Tanggal Lahir',
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            AppSizes.vSpaceSmall,
            const CustomDateTimePicker(
              label: 'Tanggal Berangkat (Disabled)',
              valueText: 'Belum memilih metode',
              onTap: null,
            ),

            _buildSectionTitle('9. Bottom Sheet Selector'),
            BottomSheetSelector(
              label: 'Metode Pembayaran',
              selectedValueText: _selectedPaymentMethod,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLarge)),
                  ),
                  builder: (BuildContext context) {
                    return Container(
                      padding: const EdgeInsets.all(AppSizes.pLarge),
                      height: 250,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pilih Metode Pembayaran', style: AppTextStyles.h2),
                          AppSizes.vSpaceMedium,
                          ListTile(
                            leading: const Icon(Icons.account_balance_wallet, color: AppColors.main),
                            title: Text('Transfer Bank Mandiri', style: AppTextStyles.bodyLarge),
                            onTap: () {
                              setState(() => _selectedPaymentMethod = 'Transfer Bank Mandiri');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.credit_card, color: AppColors.main),
                            title: Text('Kartu Kredit / Debit', style: AppTextStyles.bodyLarge),
                            onTap: () {
                              setState(() => _selectedPaymentMethod = 'Kartu Kredit / Debit');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            AppSizes.vSpaceSmall,
            const BottomSheetSelector(
              label: 'Pilih Kupon (Disabled)',
              selectedValueText: 'Tidak ada kupon aktif',
              onTap: null,
            ),

            _buildSectionTitle('10. Custom Search Bar'),
            CustomSearchBar(
              hintText: 'Cari komponen di sini...',
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              onClear: () => setState(() => _searchController.clear()),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
