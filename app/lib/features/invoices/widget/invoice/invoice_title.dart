import 'package:flutter/material.dart';

class InvoiceTitle extends StatelessWidget {
  const InvoiceTitle({
    super.key,
    required this.icon,
    this.child,
  });

  final Widget icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 20,
              child: Center(child: icon),
            ),
            Expanded(
              flex: 80,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'CNPJ - 13.228.119/0001-68\n'
                  'Publicação do estatuto no Diário Oficial de 22-06-1983\n'
                  'Reconhecido como Órgão de utilidade pública Municipal - conf.lei N 7 de 27-10-1983\n'
                  'Reconhecido como Órgão de utilidade pública Estadual - conf.lei N 7049 de 16-04-1997\n'
                  'Rua Morro do Chapéu, S/N - Tel 0(xx74) 3674-2165 - Lages do Batata - Jacobina BA\n'
                  'Email: acalages@hotmail.com',
                style: TextStyle(
                  fontSize: 18,
                ),
                textAlign: TextAlign.left,
                ),
              ),
            ),
          ],
        ),

        Divider (),

        Center(
          child: Text(
            'ACAL - Associação Comunitária e Assistencial de Lages',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'ECONOMIZAR ÁGUA É UM DEVER DE TODO SER HUMANO.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,

            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Divider()
      ],
    );
  }
}
