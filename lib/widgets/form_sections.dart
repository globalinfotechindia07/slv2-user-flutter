import 'package:flutter/material.dart';
import '../providers/loan_form_provider.dart';
import '../widgets/form_widgets.dart';
import '../widgets/file_upload.dart';
// Uses your existing select_field_popup.dart
import '../screens/select_field_popup.dart';

// ─── Step 0: Personal Details ─────────────────────────────────────────────────

class PersonalDetailsSection extends StatelessWidget {
  final LoanFormProvider provider;

  const PersonalDetailsSection({Key? key, required this.provider})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = provider.formData;
    final errors = provider.errors;

    return FormSection(
      title: 'Personal Details of Applicant',
      subtitle: 'Kindly enter your personal information below',
      children: [
        InputField(
          label: 'Full Name',
          value: data.fullName,
          onChanged: (v) => provider.updateField('fullName', v),
          error: errors['fullName'],
          placeholder: 'Enter your full name',
        ),
        InputField(
          label: 'Email',
          value: data.email,
          onChanged: (v) => provider.updateField('email', v),
          error: errors['email'],
          placeholder: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
        ),
        DatePickerField(
          label: 'Date of Birth',
          value: data.dob,
          onChanged: (v) => provider.updateField('dob', v),
          error: errors['dob'],
        ),
        SelectFieldPopup(
          label: 'Gender',
          value: data.gender,
          onChange: (v) => provider.updateField('gender', v),
          error: errors['gender'],
          options: const [
            {'value': 'male', 'label': 'Male'},
            {'value': 'female', 'label': 'Female'},
            {'value': 'other', 'label': 'Other'},
          ],
        ),
        InputField(
          label: 'Address',
          value: data.address,
          onChanged: (v) => provider.updateField('address', v),
          error: errors['address'],
          placeholder: 'Enter your address',
        ),
      ],
    );
  }
}

// ─── Step 1: Documents ────────────────────────────────────────────────────────

class DocumentsSection extends StatelessWidget {
  final LoanFormProvider provider;

  const DocumentsSection({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = provider.formData;
    final errors = provider.errors;

    return FormSection(
      title: 'Documents',
      subtitle: 'Upload your identity documents',
      children: [
        InputField(
          label: 'Aadhar Number',
          value: data.aadharNumber,
          onChanged: (v) => provider.updateField('aadharNumber', v),
          error: errors['aadharNumber'],
          placeholder: 'Enter 12-digit Aadhar number',
          keyboardType: TextInputType.number,
        ),
        FileUpload(
          label: 'Upload Front Aadhar Card (PDF/Image)',
          value: data.aadharDoc,
          onFileSelected: (file) => provider.updateFile('aadharDoc', file),
          onRemove: () => provider.updateFile('aadharDoc', null),
          error: errors['aadharDoc'],
        ),
        FileUpload(
          label: 'Upload Back Aadhar Card (PDF/Image)',
          value: data.aadharDocBack,
          onFileSelected: (file) => provider.updateFile('aadharDocBack', file),
          onRemove: () => provider.updateFile('aadharDocBack', null),
          error: errors['aadharDocBack'],
        ),
        InputField(
          label: 'PAN Number',
          value: data.panNumber,
          onChanged: (v) => provider.updateField('panNumber', v),
          error: errors['panNumber'],
          placeholder: 'Enter PAN number',
        ),
        FileUpload(
          label: 'Upload PAN Card (PDF/Image)',
          value: data.panDoc,
          onFileSelected: (file) => provider.updateFile('panDoc', file),
          onRemove: () => provider.updateFile('panDoc', null),
          error: errors['panDoc'],
        ),
      ],
    );
  }
}

// ─── Step 2: Employment ───────────────────────────────────────────────────────

class EmploymentSection extends StatelessWidget {
  final LoanFormProvider provider;

  const EmploymentSection({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = provider.formData;
    final errors = provider.errors;

    return FormSection(
      title: 'Employment Details',
      subtitle: 'Share your work information',
      children: [
        SelectFieldPopup(
          label: 'Employment Type',
          value: data.employmentType,
          onChange: (v) => provider.updateField('employmentType', v),
          error: errors['employmentType'],
          options: const [
            {'value': 'salaried', 'label': 'Salaried'},
            {'value': 'self-employed', 'label': 'Self Employed'},
            {'value': 'business', 'label': 'Business Owner'},
          ],
        ),
        InputField(
          label: 'Company Name',
          value: data.companyName,
          onChanged: (v) => provider.updateField('companyName', v),
          error: errors['companyName'],
          placeholder: 'Enter company name',
        ),
        InputField(
          label: 'Monthly Income',
          value: data.monthlyIncome,
          onChanged: (v) => provider.updateField('monthlyIncome', v),
          error: errors['monthlyIncome'],
          placeholder: 'Enter monthly income',
          keyboardType: TextInputType.number,
        ),
        SelectFieldPopup(
          label: 'Work Experience',
          value: data.workExperience,
          onChange: (v) => provider.updateField('workExperience', v),
          error: errors['workExperience'],
          options: const [
            {'value': '0-1', 'label': '0-1 years'},
            {'value': '1-3', 'label': '1-3 years'},
            {'value': '3-5', 'label': '3-5 years'},
            {'value': '5+', 'label': '5+ years'},
          ],
        ),
      ],
    );
  }
}

// ─── Step 3: Product ──────────────────────────────────────────────────────────

class ProductSection extends StatelessWidget {
  final LoanFormProvider provider;

  const ProductSection({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = provider.formData;
    final errors = provider.errors;
    final shops = provider.shops;

    return FormSection(
      title: 'Product Details',
      subtitle: 'What would you like to purchase?',
      children: [
        InputField(
          label: 'Brand',
          value: data.brand,
          onChanged: (v) => provider.updateField('brand', v),
          error: errors['brand'],
          placeholder: 'Enter brand name',
        ),
        InputField(
          label: 'Model',
          value: data.model,
          onChanged: (v) => provider.updateField('model', v),
          error: errors['model'],
          placeholder: 'Enter model name',
        ),
        InputField(
          label: 'Product Price',
          value: data.productPrice,
          onChanged: (v) => provider.updateField('productPrice', v),
          error: errors['productPrice'],
          placeholder: 'Enter product price',
          keyboardType: TextInputType.number,
        ),
        InputField(
          label: 'Down Payment',
          value: data.downPayment,
          onChanged: (v) => provider.updateField('downPayment', v),
          error: errors['downPayment'],
          placeholder: 'Enter down payment amount',
          keyboardType: TextInputType.number,
        ),
        SelectFieldPopup(
          label: 'Shop Name',
          value: data.shopName,
          onChange: (v) => provider.updateField('shopName', v),
          error: errors['shopName'],
          options: shops
              .map((shop) => {
                    'value': shop.id,
                    'label': shop.displayLabel,
                  })
              .toList(),
        ),
      ],
    );
  }
}