import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentPage(
      title: 'Terms of Service',
      lastUpdated: '16 July 2026',
      introduction:
          'Ablerite is an application developed and provided by Senrama Interactive. These Terms of Service govern your access to and use of Ablerite, our website, mobile applications and related services (collectively, the "Services"). References to "Senrama Limited", "we", "us" or "our" in these terms mean Senrama Interactive and Senrama Limited.',
      sections: [
        _LegalSection(
          heading: 'Acceptance of these terms',
          paragraphs: [
            'By accessing or using the Services, you agree to these Terms of Service and our Privacy Policy. If you do not agree, do not use the Services.',
            'If you use the Services on behalf of an organisation, you confirm that you have authority to accept these terms on its behalf.',
          ],
        ),
        _LegalSection(
          heading: 'Who may use Ablerite',
          paragraphs: [
            'The Services are not intended for children under the age of 9. If you are under the age at which you can agree to these terms in your country, a parent or legal guardian must review and accept them for you.',
          ],
        ),
        _LegalSection(
          heading: 'Your account',
          paragraphs: [
            'You are responsible for providing accurate account information, keeping your login details secure and for activity that takes place through your account. Tell us promptly if you believe your account has been accessed without permission.',
          ],
        ),
        _LegalSection(
          heading: 'Using the Services',
          paragraphs: [
            'You may use the Services only for lawful purposes and in accordance with these terms. You must not misuse, disrupt, damage or attempt to gain unauthorised access to the Services; introduce malicious code; infringe another person\'s rights; or use the Services to create, upload or share unlawful or harmful content.',
            'You must not copy, reverse engineer, resell or commercially exploit any part of the Services except where the law permits it or we have given you written permission.',
          ],
        ),
        _LegalSection(
          heading: 'Your content',
          paragraphs: [
            'You retain ownership of content you submit to the Services. You give us permission to host, process, reproduce and display that content only as needed to operate, maintain, secure and improve the Services, subject to our Privacy Policy.',
            'You are responsible for your content and must have the rights needed to provide it to us.',
          ],
        ),
        _LegalSection(
          heading: 'Artificial intelligence',
          paragraphs: [
            'Some features use artificial intelligence. AI-generated responses may be incomplete, inaccurate or unsuitable for your circumstances. You should check important information and use your own judgement before relying on a response.',
            'The Services do not provide medical, legal, financial or other professional advice and are not a substitute for a qualified professional or emergency service.',
          ],
        ),
        _LegalSection(
          heading: 'Subscriptions and payments',
          paragraphs: [
            'Some features may require a paid subscription. Prices, billing periods and renewal terms will be shown before purchase. Purchases made through an app store are also governed by that store\'s payment, cancellation and refund terms.',
          ],
        ),
        _LegalSection(
          heading: 'Our intellectual property',
          paragraphs: [
            'The Services, including their software, design, branding and content supplied by us, are owned by or licensed to Senrama Limited and are protected by intellectual property laws. These terms give you a limited, personal, non-exclusive, non-transferable and revocable right to use the Services.',
          ],
        ),
        _LegalSection(
          heading: 'Availability and changes',
          paragraphs: [
            'We work to keep the Services available and secure, but we do not guarantee uninterrupted or error-free operation. We may update, suspend or discontinue features when reasonably necessary, including for maintenance, security or product improvements.',
          ],
        ),
        _LegalSection(
          heading: 'Suspension and termination',
          paragraphs: [
            'You may stop using the Services at any time. We may restrict or terminate access if you materially breach these terms, create risk or harm for us or others, or where required by law. Provisions that by their nature should continue after termination will remain in effect.',
          ],
        ),
        _LegalSection(
          heading: 'Disclaimers and liability',
          paragraphs: [
            'The Services are provided on an "as available" basis. To the fullest extent permitted by law, we exclude warranties that are not expressly set out in these terms.',
            'Nothing in these terms excludes or limits liability where it would be unlawful to do so. Subject to that, Senrama Limited will not be liable for indirect or consequential loss, loss of profits, loss of data or loss arising from decisions made in reliance on AI-generated content.',
          ],
        ),
        _LegalSection(
          heading: 'Changes to these terms',
          paragraphs: [
            'We may update these terms to reflect changes to the Services, our practices or legal requirements. We will update the date shown above and provide additional notice where appropriate. Continuing to use the Services after an update means the revised terms apply.',
          ],
        ),
        _LegalSection(
          heading: 'Contact us',
          paragraphs: [
            'Questions about these terms can be sent to privacy@senrama.com.',
          ],
        ),
      ],
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentPage(
      title: 'Privacy Policy',
      lastUpdated: '16 July 2026',
      introduction:
          'Ablerite is an application developed and provided by Senrama Interactive. This Privacy Policy explains how Senrama Interactive and Senrama Limited ("Senrama Limited", "we", "us" or "our") handle your personal information through the Ablerite website, our mobile applications, our communications with you and any other sites or services that link to this policy (collectively, the "Services").',
      sections: [
        _LegalSection(
          heading: 'General',
          paragraphs: [
            'Conversational artificial intelligence promises to transform how people interact with computers in everyday life. Our mission is to use this technology to create conversational partners that are safe, intelligent, compassionate and engaging.',
            'Understanding how people communicate and collaborate with AI helps us operate and improve our systems. Transparency is central to that work. This policy describes the information we collect, how we use it and the measures we take to protect it.',
          ],
        ),
        _LegalSection(
          heading: 'Information you provide to us',
          paragraphs: [
            'We may collect contact and account information, such as your first and last name, email address and phone number.',
            'We collect the content and metadata of messages or other material you submit through the Services or send directly to Senrama Limited.',
            'We collect communications we exchange with you, including when you contact us with questions or feedback or respond to a survey.',
            'We may collect other information that you choose to provide. We will use it as described in this policy or as disclosed when it is collected.',
          ],
        ),
        _LegalSection(
          heading: 'Information collected when you use the Services',
          paragraphs: [
            'We may collect information needed to operate and secure the Services, such as device and app information, log and diagnostic data, feature interactions and approximate location derived from an IP address.',
          ],
        ),
        _LegalSection(
          heading: 'How we use your information',
          paragraphs: [
            'We use personal information to operate, maintain and provide the Services; create and manage accounts; respond to requests; personalise your experience; process transactions; monitor performance; prevent fraud, misuse and security incidents; comply with legal obligations; and enforce our Terms of Service.',
            'We may also use interactions and feedback to evaluate and improve our products and AI systems. Where required, we will use appropriate safeguards or ask for consent.',
          ],
        ),
        _LegalSection(
          heading: 'How we share information',
          paragraphs: [
            'We may share information with service providers that support functions such as hosting, authentication, analytics, customer support, payments and security. They may process information only for the services they provide to us and under appropriate obligations.',
            'We may also disclose information where required by law, to protect the rights and safety of users or others, in connection with a corporate transaction, or when you ask us to or give your consent. We do not sell your personal information.',
          ],
        ),
        _LegalSection(
          heading: 'Data retention',
          paragraphs: [
            'We keep personal information only for as long as reasonably necessary for the purposes described in this policy, including providing the Services, meeting legal and accounting requirements, resolving disputes and maintaining security. Retention periods vary according to the type of information and why it is held.',
          ],
        ),
        _LegalSection(
          heading: 'Security',
          paragraphs: [
            'Security is integral to conversational AI. We use reasonable technical and organisational measures designed to protect personal information. No method of storage or transmission is completely secure, so we cannot guarantee absolute security.',
          ],
        ),
        _LegalSection(
          heading: 'Your choices and rights',
          paragraphs: [
            'Depending on where you live, you may have rights relating to your personal information, including asking to access, correct or delete it, restrict or object to certain processing, or receive a portable copy. You may also withdraw consent where processing is based on consent.',
            'To make a request, contact us using the address below. We may need to verify your identity before completing it.',
          ],
        ),
        _LegalSection(
          heading: 'Children',
          paragraphs: [
            'Our Services are not intended for children under the age of 9. We do not knowingly collect or solicit personal information from children under 9. If you believe a child under 9 has provided personal information, please contact us so we can take appropriate action.',
          ],
        ),
        _LegalSection(
          heading: 'Changes to this policy',
          paragraphs: [
            'We may update this policy as our Services, practices or legal obligations change. We will revise the date shown above and provide additional notice where appropriate.',
          ],
        ),
        _LegalSection(
          heading: 'How to contact us',
          paragraphs: [
            'Please contact the Senrama Interactive team at privacy@senrama.com with privacy questions or requests.',
          ],
        ),
      ],
    );
  }
}

class _LegalDocumentPage extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final String introduction;
  final List<_LegalSection> sections;

  const _LegalDocumentPage({
    required this.title,
    required this.lastUpdated,
    required this.introduction,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                'Last updated: $lastUpdated',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                introduction,
                style: textTheme.bodyLarge?.copyWith(height: 1.55),
              ),
              const SizedBox(height: 24),
              for (final section in sections) ...[
                Text(
                  section.heading,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final paragraph in section.paragraphs) ...[
                  Text(
                    paragraph,
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                      color: colors.onSurface.withAlpha(210),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  final String heading;
  final List<String> paragraphs;

  const _LegalSection({required this.heading, required this.paragraphs});
}
