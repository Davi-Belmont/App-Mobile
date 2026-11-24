// Responsável: Cainã Coutinho (Tela de Login / Acesso)
import 'package:flutter/material.dart';
import 'package:study_planner/core/theme/app_colors.dart';
import 'package:study_planner/data/api_client.dart';

enum _ServerStatus { checking, online, offline }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  _ServerStatus _status = _ServerStatus.checking;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// GET /health — mostra se a API está no ar.
  Future<void> _checkServer() async {
    setState(() => _status = _ServerStatus.checking);
    try {
      await ApiClient.instance.get('/health');
      if (mounted) setState(() => _status = _ServerStatus.online);
    } on ApiException {
      if (mounted) setState(() => _status = _ServerStatus.offline);
    }
  }

  /// A API do PDF não tem autenticação: o login é apenas visual por enquanto.
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Hero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Bem-vindo de volta',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    const Text('Entre para acessar suas disciplinas, tarefas e notas.',
                        style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline_rounded)),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Informe seu e-mail';
                        if (!t.contains('@') || !t.contains('.')) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 4) ? 'A senha precisa ter ao menos 4 caracteres' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () {}, child: const Text('Esqueci a senha')),
                    ),
                    const SizedBox(height: 4),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: () {}, child: const Text('Criar conta')),
                    const SizedBox(height: 24),
                    Center(child: _ServerChip(status: _status, onRetry: _checkServer)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 48, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Icon(Icons.school_rounded, size: 40, color: AppColors.primary),
          ),
          SizedBox(height: 16),
          Text('StudyPlanner', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text('Organizador acadêmico', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 14)),
        ],
      ),
    );
  }
}

class _ServerChip extends StatelessWidget {
  const _ServerChip({required this.status, required this.onRetry});
  final _ServerStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      _ServerStatus.checking => ('Verificando servidor…', AppColors.textMuted, const Color(0xFFF3F4F6)),
      _ServerStatus.online => ('Servidor online', AppColors.success, AppColors.successBg),
      _ServerStatus.offline => ('Servidor offline · toque para tentar de novo', AppColors.danger, AppColors.dangerBg),
    };
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: status == _ServerStatus.offline ? onRetry : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
