import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/quality/data/quality_analysis_service.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/app_form_dialog.dart';
import 'package:acalapp/shared/widgets/labeled_field.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QualityAnalysisFormPage extends StatefulWidget {
  final QualityAnalysis? analysis;
  final QualityAnalysisService? analysisService;

  const QualityAnalysisFormPage({super.key, this.analysis, this.analysisService});

  @override
  State<QualityAnalysisFormPage> createState() => _QualityAnalysisFormPageState();
}

class _ParamControllers {
  _ParamControllers()
      : required = TextEditingController(text: '0'),
        analyzed = TextEditingController(text: '0'),
        compliant = TextEditingController(text: '0');

  final TextEditingController required;
  final TextEditingController analyzed;
  final TextEditingController compliant;

  void dispose() {
    required.dispose();
    analyzed.dispose();
    compliant.dispose();
  }
}

class _QualityAnalysisFormPageState extends State<QualityAnalysisFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final QualityAnalysisService _service;

  late int _month;
  late int _year;

  // Editing an existing single record.
  late String _paramName;
  late final TextEditingController _requiredController;
  late final TextEditingController _analyzedController;
  late final TextEditingController _compliantController;

  // Creating a new period: one set of fields per parameter.
  final Map<String, _ParamControllers> _paramControllers = {
    for (final p in qualityAnalysisParamNames) p: _ParamControllers(),
  };

  bool _saving = false;

  bool get _isEditing => widget.analysis != null;
  String get _toastMessage => _isEditing ? 'Análise atualizada com sucesso.' : 'Análise criada com sucesso.';
  String get _title => _isEditing ? 'Editar Análise' : 'Adicionar Análise';

  @override
  void initState() {
    super.initState();
    _service = widget.analysisService ?? QualityAnalysisService();

    final analysis = widget.analysis;
    final now = DateTime.now();
    _month = analysis?.referenceDate.month ?? now.month;
    _year = analysis?.referenceDate.year ?? now.year;
    _paramName = analysis?.paramName ?? qualityAnalysisParamNames.first;
    _requiredController = TextEditingController(text: analysis?.required.toString() ?? '');
    _analyzedController = TextEditingController(text: analysis?.analyzed.toString() ?? '');
    _compliantController = TextEditingController(text: analysis?.compliant.toString() ?? '');
  }

  @override
  void dispose() {
    _requiredController.dispose();
    _analyzedController.dispose();
    _compliantController.dispose();
    for (final c in _paramControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateCount(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obrigatório';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await _service.update(QualityAnalysis(
          id: widget.analysis!.id,
          referenceDate: DateTime(_year, _month),
          paramName: _paramName,
          required: int.parse(_requiredController.text.trim()),
          analyzed: int.parse(_analyzedController.text.trim()),
          compliant: int.parse(_compliantController.text.trim()),
        ));
      } else {
        for (final paramName in qualityAnalysisParamNames) {
          final controllers = _paramControllers[paramName]!;
          await _service.create(QualityAnalysis(
            referenceDate: DateTime(_year, _month),
            paramName: paramName,
            required: int.parse(controllers.required.text.trim()),
            analyzed: int.parse(controllers.analyzed.text.trim()),
            compliant: int.parse(controllers.compliant.text.trim()),
          ));
        }
      }
      if (mounted) {
        AppToast.success(context, _toastMessage);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, _errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorMessage(Object e) {
    if (e is! ApiException) return 'Erro ao salvar análise.';

    final errorCode = ApiErrorCode.fromCode(e.code);
    if (errorCode != null) return errorCode.description;

    return 'Erro ao salvar análise.';
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = [for (var y = currentYear - 5; y <= currentYear + 1; y++) y];

    return AppFormDialog(
      formKey: _formKey,
      title: _title,
      onSave: _save,
      saving: _saving,
      maxWidth: _isEditing ? 480 : 680,
      fields: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditing) ...[
            Text(
              'Insira os resultados das medições de laboratório para o período.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: LabeledField(
                  label: _isEditing ? 'Mês de Referência' : 'Período de Referência',
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: [
                      for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text(monthNames[m - 1])),
                    ],
                    onChanged: (v) => setState(() => _month = v!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField(
                  label: _isEditing ? 'Ano' : ' ',
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: [for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))],
                    onChanged: (v) => setState(() => _year = v!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditing) ..._editingFields() else ..._creationFields(),
        ],
      ),
    );
  }

  List<Widget> _editingFields() => [
        LabeledField(
          label: 'Parâmetro',
          child: DropdownButtonFormField<String>(
            initialValue: _paramName,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              for (final p in qualityAnalysisParamNames) DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (v) => setState(() => _paramName = v!),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledField(
                label: 'Exigido',
                child: TextFormField(
                  controller: _requiredController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: _validateCount,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledField(
                label: 'Analisado',
                child: TextFormField(
                  controller: _analyzedController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: _validateCount,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledField(
                label: 'Conformidade',
                child: TextFormField(
                  controller: _compliantController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: _validateCount,
                ),
              ),
            ),
          ],
        ),
      ];

  List<Widget> _creationFields() => [
        Row(
          children: [
            const Expanded(flex: 4, child: SizedBox()),
            Expanded(
              child: Text(
                'Exigido',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Analisado',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Conformidade',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final paramName in qualityAnalysisParamNames) ...[
          _ParamRow(paramName: paramName, controllers: _paramControllers[paramName]!, validator: _validateCount),
          const SizedBox(height: 8),
        ],
      ];
}

class _ParamRow extends StatelessWidget {
  const _ParamRow({required this.paramName, required this.controllers, required this.validator});

  final String paramName;
  final _ParamControllers controllers;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              const Text('•  ', style: TextStyle(fontSize: 18)),
              Expanded(child: Text(paramName, style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controllers.required,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: validator,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controllers.analyzed,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: validator,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controllers.compliant,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
