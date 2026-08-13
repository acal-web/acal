import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/quality/data/quality_analysis_service.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/app_form_dialog.dart';
import 'package:acalapp/shared/widgets/period_filter_button.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

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
  late final TextEditingController _referenceController;

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
    _referenceController = TextEditingController(text: formatMonthReference(DateTime(_year, _month)));
  }

  @override
  void didUpdateWidget(QualityAnalysisFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _referenceController.text = formatMonthReference(DateTime(_year, _month));
  }

  @override
  void dispose() {
    _requiredController.dispose();
    _analyzedController.dispose();
    _compliantController.dispose();
    _referenceController.dispose();
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

  Future<void> _pickReference() async {
    final result = await pickMonthYear(context, initial: (year: _year, month: _month));
    if (result != null) {
      setState(() {
        _year = result.year;
        _month = result.month;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          SizedBox(
            width: 200,
            child: FTextFormField(
              control: FTextFieldControl.managed(controller: _referenceController),
              readOnly: true,
              label: Text(_isEditing ? 'Mês de Referência' : 'Período de Referência'),
              suffixBuilder: (context, style, variants) => const Icon(Icons.calendar_today, size: 18),
              onTap: _pickReference,
            ),
          ),
          const SizedBox(height: 12),
          if (_isEditing) ..._editingFields() else ..._creationFields(),
        ],
      ),
    );
  }

  List<Widget> _editingFields() => [
        FSelect<String>(
          items: {for (final p in qualityAnalysisParamNames) p: p},
          control: FSelectControl.managed(initial: _paramName, onChange: (v) => setState(() => _paramName = v!)),
          label: const Text('Parâmetro'),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FTextFormField(
                control: FTextFieldControl.managed(controller: _requiredController),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                label: const Text('Exigido'),
                validator: _validateCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FTextFormField(
                control: FTextFieldControl.managed(controller: _analyzedController),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                label: const Text('Analisado'),
                validator: _validateCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FTextFormField(
                control: FTextFieldControl.managed(controller: _compliantController),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                label: const Text('Conformidade'),
                validator: _validateCount,
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
          child: FTextFormField(
            control: FTextFieldControl.managed(controller: controllers.required),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            validator: validator,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FTextFormField(
            control: FTextFieldControl.managed(controller: controllers.analyzed),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            validator: validator,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FTextFormField(
            control: FTextFieldControl.managed(controller: controllers.compliant),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            validator: validator,
          ),
        ),
      ],
    );
  }
}
