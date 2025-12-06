import type {
  NavigationLink,
  CTAButton,
  HeroContent,
  FeaturesContent,
  Feature,
  FooterLink,
} from '../types/landing.types'

export const NAVIGATION_LINKS: NavigationLink[] = [
  { label: 'Features', href: '#features' },
  { label: 'Docs', href: 'https://www.notion.so/ajy720/SoftBank-Hackathon-2025-Team-Yellow-2b9a0048876b80359945da260b4bc659', isExternal: true },
  { label: 'GitHub', href: 'https://github.com/Softbank-Hackathon-2025-Team-Yellow', isExternal: true },
]

export const HERO_CONTENT: HeroContent = {
  headline: 'Call it. It runs.',
  description: {
    ko: 'Runna는 당신을 위한 미니멀 서버리스 엔진입니다.\n필요할 때는 즉시 달리고, 필요 없을 때는 완전히 멈춥니다.\n제로 스케일링으로 최고의 비용 효율성을 실현하세요.',
    ja: 'Runnaは、あなたのためのミニマルなサーバーレスエンジンです。\n必要なときは即座に走り、不要なときは完全に停止します。\nゼロスケールで最高のコスト効率を実現しましょう。',
  },
}

export const CTA_BUTTONS: { primary: CTAButton; secondary: CTAButton } = {
  primary: { label: 'Run Function', href: '/create' },
  secondary: { label: 'View Functions', href: '/gallery' },
}

export const FEATURES_CONTENT: FeaturesContent = {
  heading: 'Simple, Fast, and Efficient',
  subheading: {
    ko: '심플함과 성능을 중시하는 개발자를 위해 설계되었습니다. 최소한의 설정으로 함수를 빠르게 실행할 수 있습니다.',
    ja: 'シンプルさとパフォーマンスを重視する開発者のために設計されています。最小限の設定で関数を素早く実行できます。',
  },
}

export const FEATURES: Feature[] = [
  {
    id: 'sync-async',
    title: 'Sync & Async Execution',
    description: {
      ko: '즉시 실행되는 작업이든 장시간 실행되는 작업이든, 모든 실행 모델을 쉽게 처리할 수 있습니다.',
      ja: '即座に実行されるタスクでも長時間実行されるタスクでも、あらゆる実行モデルを簡単に処理できます。',
    },
    icon: 'sync',
  },
  {
    id: 'autoscaling',
    title: 'Knative Autoscaling',
    description: {
      ko: '리소스를 자동으로 조정하고 제로까지 스케일 다운하는 지능형 비용 효율적 스케일링의 이점을 누릴 수 있습니다.',
      ja: 'リソースを自動的に調整し、ゼロまでスケールダウンする、インテリジェントでコスト効率の高いスケーリングの恩恵を受けられます。',
    },
    icon: 'scale',
  },
]

export const FOOTER_LINKS: FooterLink[] = [
  { label: 'Features', href: '#features' },
  { label: 'Docs', href: 'https://www.notion.so/ajy720/SoftBank-Hackathon-2025-Team-Yellow-2b9a0048876b80359945da260b4bc659' },
  { label: 'GitHub', href: 'https://github.com/Softbank-Hackathon-2025-Team-Yellow' },
  { label: 'Contact', href: '#contact' },
]

export const COPYRIGHT_TEXT = '© 2025 Runna — SoftBank Hackathon 2025, Yellow Team'
