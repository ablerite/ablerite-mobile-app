import React from 'react';
import {
  AbsoluteFill,
  Img,
  interpolate,
  Sequence,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';

const green = '#17AB77';
const darkGreen = '#0B6246';
const ink = '#102A21';
const muted = '#65766F';
const surface = '#F4F8F6';
const font = "Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

const smooth = (frame: number, input: number[], output: number[]) =>
  interpolate(frame, input, output, {...clamp, easing: (t) => t * t * (3 - 2 * t)});

const ProgressDots: React.FC<{active: number}> = ({active}) => (
  <div style={{display: 'flex', gap: 12, alignItems: 'center'}}>
    {[0, 1, 2].map((index) => (
      <div
        key={index}
        style={{
          width: index === active ? 56 : 15,
          height: 15,
          borderRadius: 20,
          background: index === active ? green : '#CCD6D1',
        }}
      />
    ))}
  </div>
);

const Button: React.FC<{children: React.ReactNode; enabled?: boolean; pressed?: boolean}> = ({
  children,
  enabled = true,
  pressed = false,
}) => (
  <div
    style={{
      height: 94,
      borderRadius: 28,
      background: enabled ? green : '#D5DDD9',
      color: enabled ? 'white' : '#8B9993',
      display: 'grid',
      placeItems: 'center',
      fontSize: 29,
      fontWeight: 780,
      boxShadow: enabled ? '0 16px 34px rgba(23,171,119,.25)' : 'none',
      transform: `scale(${pressed ? 0.965 : 1})`,
    }}
  >
    {children}
  </div>
);

const PainRow: React.FC<{icon: string; label: string; selected: boolean}> = ({icon, label, selected}) => (
  <div
    style={{
      height: 71,
      borderRadius: 22,
      background: selected ? green : '#EAF0ED',
      color: selected ? 'white' : ink,
      display: 'flex',
      alignItems: 'center',
      padding: '0 27px',
      gap: 22,
      fontSize: 25,
      fontWeight: 730,
      boxShadow: selected ? '0 13px 26px rgba(23,171,119,.22)' : 'none',
      transform: `scale(${selected ? 1.015 : 1})`,
    }}
  >
    <span style={{width: 34, color: selected ? 'white' : green, fontSize: 26, textAlign: 'center'}}>{icon}</span>
    {label}
    {selected && <span style={{marginLeft: 'auto', fontSize: 25}}>✓</span>}
  </div>
);

const Feature: React.FC<{icon: string; title: string; body: string}> = ({icon, title, body}) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: 22,
      padding: 24,
      borderRadius: 26,
      background: 'white',
      border: '1px solid #E0E8E4',
      boxShadow: '0 12px 28px rgba(16,42,33,.05)',
    }}
  >
    <div style={{width: 72, height: 72, flex: '0 0 auto', borderRadius: 99, background: '#DDF5EB', color: green, display: 'grid', placeItems: 'center', fontSize: 31}}>
      {icon}
    </div>
    <div>
      <div style={{fontSize: 27, fontWeight: 800, color: ink}}>{title}</div>
      <div style={{fontSize: 21, lineHeight: 1.35, color: muted, marginTop: 4}}>{body}</div>
    </div>
  </div>
);

const ScreenShell: React.FC<React.PropsWithChildren<{active: number; back?: boolean}>> = ({active, back, children}) => (
  <div style={{position: 'absolute', inset: 0, padding: '50px 44px 42px', background: '#FBFDFC', display: 'flex', flexDirection: 'column'}}>
    <div style={{height: 50, display: 'flex', alignItems: 'center'}}>
      <ProgressDots active={active} />
      {back && <div style={{marginLeft: 'auto', color: green, fontWeight: 700, fontSize: 22}}>Back</div>}
    </div>
    {children}
  </div>
);

const QuestionScreen: React.FC<{selected: boolean; pressed: boolean}> = ({selected, pressed}) => {
  const points = [
    ['♡', 'Health'],
    ['▣', 'Wealth'],
    ['◎', 'Relationships'],
    ['♨', 'Stress'],
    ['◌', 'Anxiety'],
    ['✦', 'Manifestation'],
  ];
  return (
    <ScreenShell active={0}>
      <Img src={staticFile('assets/images/onboarding/pain_points.png')} style={{height: 360, width: '100%', objectFit: 'cover', borderRadius: 34, marginTop: 23, boxShadow: '0 20px 48px rgba(16,42,33,.12)'}} />
      <div style={{fontSize: 39, fontWeight: 840, color: ink, lineHeight: 1.05, letterSpacing: -1.5, marginTop: 29}}>What do you want to solve?</div>
      <div style={{fontSize: 23, color: muted, lineHeight: 1.35, marginTop: 13}}>Choose the pressure point you want Ablerite to help with first.</div>
      <div style={{display: 'grid', gap: 10, marginTop: 24}}>
        {points.map(([icon, label]) => <PainRow key={label} icon={icon} label={label} selected={selected && label === 'Health'} />)}
      </div>
      <div style={{marginTop: 'auto'}}><Button enabled={selected} pressed={pressed}>Continue</Button></div>
    </ScreenShell>
  );
};

const GuidanceScreen: React.FC<{pressed: boolean}> = ({pressed}) => (
  <ScreenShell active={1} back>
    <Img src={staticFile('assets/images/onboarding/free_media.png')} style={{height: 430, width: '100%', objectFit: 'cover', borderRadius: 34, marginTop: 23, boxShadow: '0 20px 48px rgba(16,42,33,.12)'}} />
    <div style={{fontSize: 41, fontWeight: 840, color: ink, lineHeight: 1.05, letterSpacing: -1.6, marginTop: 35}}>Start with free guidance</div>
    <div style={{fontSize: 23, color: muted, lineHeight: 1.42, marginTop: 17}}>Use guided lessons, habits, and simple action steps to build a healthier rhythm without overwhelm.</div>
    <div style={{display: 'grid', gap: 17, marginTop: 35}}>
      <Feature icon="♫" title="Listen and learn" body="Use free media to understand the problem." />
      <Feature icon="▤" title="Build perspective" body="Open the courses and insights that match it." />
    </div>
    <div style={{marginTop: 'auto'}}><Button pressed={pressed}>Next</Button></div>
  </ScreenShell>
);

const ActionScreen: React.FC<{pressed: boolean}> = ({pressed}) => (
  <ScreenShell active={2} back>
    <Img src={staticFile('assets/images/onboarding/action_tools.png')} style={{height: 430, width: '100%', objectFit: 'cover', borderRadius: 34, marginTop: 23, boxShadow: '0 20px 48px rgba(16,42,33,.12)'}} />
    <div style={{fontSize: 41, fontWeight: 840, color: ink, lineHeight: 1.05, letterSpacing: -1.6, marginTop: 35}}>Turn insight into action</div>
    <div style={{fontSize: 23, color: muted, lineHeight: 1.42, marginTop: 17}}>Set goals, break them into tasks, and use the tools daily so progress becomes visible.</div>
    <div style={{display: 'grid', gap: 17, marginTop: 35}}>
      <Feature icon="⚑" title="Create a goal" body="Make the outcome specific and trackable." />
      <Feature icon="✓" title="Do the next step" body="Use tasks, focus, boards, and reminders." />
    </div>
    <div style={{marginTop: 'auto'}}><Button pressed={pressed}>Start Building</Button></div>
  </ScreenShell>
);

const Cursor: React.FC = () => {
  const frame = useCurrentFrame();
  let x = 0;
  let y = 0;
  let opacity = 0;
  let tapAt = -100;

  if (frame >= 105 && frame <= 258) {
    x = smooth(frame, [105, 145, 185, 225], [1030, 835, 835, 540]);
    y = smooth(frame, [105, 145, 185, 225], [1000, 1000, 1000, 1640]);
    opacity = Math.min(interpolate(frame, [105, 120], [0, 1], clamp), interpolate(frame, [245, 258], [1, 0], clamp));
    tapAt = frame < 185 ? 155 : 230;
  } else if (frame >= 370 && frame <= 462) {
    x = smooth(frame, [370, 415], [1000, 540]);
    y = smooth(frame, [370, 415], [1640, 1640]);
    opacity = Math.min(interpolate(frame, [370, 384], [0, 1], clamp), interpolate(frame, [447, 462], [1, 0], clamp));
    tapAt = 425;
  } else if (frame >= 570 && frame <= 675) {
    x = smooth(frame, [570, 625], [1000, 540]);
    y = smooth(frame, [570, 625], [1640, 1640]);
    opacity = Math.min(interpolate(frame, [570, 584], [0, 1], clamp), interpolate(frame, [660, 675], [1, 0], clamp));
    tapAt = 640;
  }

  const distance = Math.abs(frame - tapAt);
  const press = interpolate(distance, [0, 8], [0.78, 1], clamp);
  const ring = interpolate(distance, [0, 15], [0.35, 1.8], clamp);
  const ringOpacity = interpolate(distance, [0, 15], [0.7, 0], clamp);

  return (
    <div style={{position: 'absolute', zIndex: 50, left: x, top: y, opacity, pointerEvents: 'none'}}>
      <div style={{position: 'absolute', width: 70, height: 70, left: -35, top: -35, borderRadius: 99, border: `5px solid ${green}`, transform: `scale(${ring})`, opacity: ringOpacity}} />
      <svg width="80" height="100" viewBox="0 0 80 100" style={{position: 'absolute', left: -17, top: -13, transform: `scale(${press})`, transformOrigin: '18px 12px', filter: 'drop-shadow(0 8px 10px rgba(0,0,0,.25))'}}>
        <path d="M10 6 L10 63 C10 80 23 92 40 92 C57 92 70 80 70 63 V39 C70 33 66 29 60 29 C57 29 54 31 52 34 C51 28 47 25 42 25 C38 25 35 27 33 31 C31 26 27 24 23 24 C20 24 17 25 15 28 V6 C15 2 10 2 10 6Z" fill="white" stroke="#102A21" strokeWidth="4" strokeLinejoin="round" />
      </svg>
    </div>
  );
};

const Headline: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame, fps, config: {damping: 16, stiffness: 95}});
  const steps = frame < 270 ? ['Make it personal', 'Answer one simple question'] : frame < 480 ? ['Learn your way', 'Get guidance that fits'] : frame < 690 ? ['Move forward', 'Turn insight into action'] : ['You’re ready', 'Build momentum every day'];
  return (
    <div style={{position: 'absolute', left: 72, right: 72, top: 72, display: 'flex', alignItems: 'center', opacity: p, transform: `translateY(${interpolate(p, [0,1],[35,0])}px)`}}>
      <Img src={staticFile('assets/ablerite_logo_rounded.png')} style={{width: 72, height: 72, borderRadius: 19, boxShadow: '0 10px 24px rgba(0,0,0,.12)'}} />
      <div style={{marginLeft: 21}}>
        <div style={{fontSize: 25, textTransform: 'uppercase', letterSpacing: 2, color: '#BFF4E0', fontWeight: 780}}>{steps[0]}</div>
        <div style={{fontSize: 39, color: 'white', fontWeight: 820, letterSpacing: -1.5, marginTop: 3}}>{steps[1]}</div>
      </div>
    </div>
  );
};

const Success: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const local = frame - 690;
  const p = spring({frame: local, fps, config: {damping: 13, stiffness: 88}});
  const rays = Array.from({length: 18});
  return (
    <AbsoluteFill style={{zIndex: 35, opacity: interpolate(local, [0, 18], [0, 1], clamp), background: 'linear-gradient(155deg, #092E24, #0B6246 45%, #17AB77 125%)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', textAlign: 'center', color: 'white'}}>
      <div style={{position: 'relative', width: 260, height: 260, display: 'grid', placeItems: 'center'}}>
        {rays.map((_, i) => {
          const angle = (i / rays.length) * Math.PI * 2;
          const distance = interpolate(p, [0,1],[25,155]);
          return <div key={i} style={{position: 'absolute', width: i % 3 === 0 ? 16 : 10, height: i % 3 === 0 ? 16 : 10, borderRadius: 99, background: i % 2 === 0 ? '#8CF1CB' : '#FFE59A', left: 122 + Math.cos(angle) * distance, top: 122 + Math.sin(angle) * distance, opacity: interpolate(p,[0,.3,1],[0,1,.65])}} />;
        })}
        <div style={{width: 170, height: 170, borderRadius: 99, background: 'white', color: green, display: 'grid', placeItems: 'center', fontSize: 88, fontWeight: 900, boxShadow: '0 30px 70px rgba(0,0,0,.25)', transform: `scale(${p})`}}>✓</div>
      </div>
      <div style={{fontSize: 91, lineHeight: .98, fontWeight: 870, letterSpacing: -5, marginTop: 70, opacity: p, transform: `translateY(${interpolate(p,[0,1],[45,0])}px)`}}>Your journey<br />starts now.</div>
      <div style={{fontSize: 31, lineHeight: 1.4, color: 'rgba(255,255,255,.72)', maxWidth: 790, marginTop: 38, opacity: p}}>Personal guidance, practical tools and visible progress—all in one place.</div>
      <div style={{display: 'flex', alignItems: 'center', gap: 20, marginTop: 110, opacity: p}}>
        <Img src={staticFile('assets/ablerite_logo_rounded.png')} style={{width: 82, height: 82, borderRadius: 22}} />
        <div style={{fontSize: 43, fontWeight: 820}}>Ablerite</div>
      </div>
    </AbsoluteFill>
  );
};

const PreludeShell: React.FC<React.PropsWithChildren<{duration: number; light?: boolean}>> = ({duration, light = false, children}) => {
  const frame = useCurrentFrame();
  const opacity = Math.min(
    interpolate(frame, [0, 16], [0, 1], clamp),
    interpolate(frame, [duration - 18, duration], [1, 0], clamp),
  );
  return (
    <AbsoluteFill style={{opacity, overflow: 'hidden', fontFamily: font, color: light ? ink : 'white', background: light ? 'linear-gradient(155deg, #FBFDFC, #E9F7F1)' : 'linear-gradient(155deg, #092E24, #0B6246 52%, #17AB77 130%)'}}>
      <div style={{position: 'absolute', width: 720, height: 720, borderRadius: '50%', right: -330, top: -280, background: light ? 'rgba(23,171,119,.10)' : 'rgba(113,235,191,.12)', filter: 'blur(22px)'}} />
      <div style={{position: 'absolute', width: 630, height: 630, borderRadius: '50%', left: -330, bottom: -280, background: light ? 'rgba(220,198,245,.16)' : 'rgba(255,229,154,.08)', filter: 'blur(25px)'}} />
      {children}
    </AbsoluteFill>
  );
};

const MobileFrame: React.FC<React.PropsWithChildren<{eyebrow: string; heading: string}>> = ({eyebrow, heading, children}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame: frame - 4, fps, config: {damping: 17, stiffness: 88}});
  return (
    <>
      <div style={{position: 'absolute', left: 72, right: 72, top: 72, display: 'flex', alignItems: 'center', opacity: p, transform: `translateY(${interpolate(p,[0,1],[30,0])}px)`}}>
        <Img src={staticFile('assets/ablerite_logo_rounded.png')} style={{width: 72, height: 72, borderRadius: 19, boxShadow: '0 10px 24px rgba(0,0,0,.12)'}} />
        <div style={{marginLeft: 20}}>
          <div style={{fontSize: 22, color: '#BFF4E0', fontWeight: 800, textTransform: 'uppercase', letterSpacing: 2.3}}>{eyebrow}</div>
          <div style={{fontSize: 38, color: 'white', fontWeight: 830, letterSpacing: -1.4, marginTop: 2}}>{heading}</div>
        </div>
      </div>
      <div style={{position: 'absolute', left: 95, top: 250, width: 890, height: 1520, borderRadius: 64, overflow: 'hidden', background: '#FBFDFC', border: '9px solid rgba(255,255,255,.92)', boxShadow: '0 55px 120px rgba(0,0,0,.34)', opacity: p, transform: `translateY(${interpolate(p,[0,1],[100,0])}px) scale(${.94 + p * .06})`}}>
        <div style={{position: 'absolute', top: 15, left: '50%', transform: 'translateX(-50%)', width: 140, height: 28, borderRadius: 99, background: ink, zIndex: 20}} />
        {children}
      </div>
    </>
  );
};

const SceneTap: React.FC<{tapAt: number}> = ({tapAt}) => {
  const frame = useCurrentFrame();
  const x = smooth(frame, [tapAt - 42, tapAt - 7], [1010, 540]);
  const y = smooth(frame, [tapAt - 42, tapAt - 7], [1650, 1650]);
  const opacity = Math.min(interpolate(frame, [tapAt - 42, tapAt - 28], [0, 1], clamp), interpolate(frame, [tapAt + 14, tapAt + 27], [1, 0], clamp));
  const d = Math.abs(frame - tapAt);
  const press = interpolate(d, [0, 8], [.78, 1], clamp);
  const ring = interpolate(d, [0, 15], [.35, 1.8], clamp);
  return (
    <div style={{position: 'absolute', zIndex: 60, left: x, top: y, opacity}}>
      <div style={{position: 'absolute', width: 70, height: 70, left: -35, top: -35, borderRadius: 99, border: `5px solid ${green}`, transform: `scale(${ring})`, opacity: interpolate(d,[0,15],[.7,0],clamp)}} />
      <svg width="80" height="100" viewBox="0 0 80 100" style={{position: 'absolute', left: -17, top: -13, transform: `scale(${press})`, transformOrigin: '18px 12px', filter: 'drop-shadow(0 8px 10px rgba(0,0,0,.25))'}}>
        <path d="M10 6 L10 63 C10 80 23 92 40 92 C57 92 70 80 70 63 V39 C70 33 66 29 60 29 C57 29 54 31 52 34 C51 28 47 25 42 25 C38 25 35 27 33 31 C31 26 27 24 23 24 C20 24 17 25 15 28 V6 C15 2 10 2 10 6Z" fill="white" stroke="#102A21" strokeWidth="4" strokeLinejoin="round" />
      </svg>
    </div>
  );
};

const HolisticIntro: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const copy = spring({frame: frame - 16, fps, config: {damping: 17, stiffness: 92}});
  const areas = ['Mind', 'Body', 'Purpose', 'Relationships', 'Wealth', 'Growth'];
  return (
    <PreludeShell duration={180}>
      <MobileFrame eyebrow="Welcome to Ablerite" heading="Your growth journey starts here">
        <div style={{position: 'absolute', inset: '78px 44px 42px', display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center'}}>
          <Img src={staticFile('assets/ablerite_logo_rounded.png')} style={{width: 150, height: 150, borderRadius: 40, marginTop: 60, boxShadow: '0 22px 50px rgba(23,171,119,.22)', opacity: copy, transform: `scale(${.78 + copy * .22})`}} />
          <div style={{fontSize: 24, color: darkGreen, fontWeight: 810, textTransform: 'uppercase', letterSpacing: 2.5, marginTop: 65, opacity: copy}}>More than a productivity app</div>
          <div style={{fontSize: 59, lineHeight: 1, fontWeight: 880, letterSpacing: -3.5, color: ink, marginTop: 26, opacity: copy}}>A Holistic Self Growth &amp; Development Suite</div>
          <div style={{fontSize: 27, lineHeight: 1.4, color: muted, marginTop: 31, maxWidth: 740, opacity: copy}}>Grow, organise and thrive in every area of your life—from one mobile app.</div>
          <div style={{display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: 12, marginTop: 46}}>
            {areas.map((area, i) => {
              const p = spring({frame: frame - 40 - i * 4, fps, config: {damping: 17, stiffness: 105}});
              return <div key={area} style={{padding: '15px 21px', borderRadius: 999, background: '#E5F5EF', color: darkGreen, fontSize: 21, fontWeight: 730, opacity: p}}><span style={{color: green, marginRight: 7}}>✓</span>{area}</div>;
            })}
          </div>
          <div style={{marginTop: 'auto', width: '100%'}}><Button pressed={Math.abs(frame - 145) < 7}>Discover Ablerite</Button></div>
        </div>
      </MobileFrame>
      <SceneTap tapAt={145} />
    </PreludeShell>
  );
};

const FeatureTools: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const features = [
    {title: 'Brain Training', body: 'Focus, memory and mental agility.', image: 'assets/images/app_banners/braintraining.png'},
    {title: 'Visualization', body: 'Picture and rehearse your future.', image: 'assets/images/visualization/visionboards.png'},
    {title: 'Manifestation', body: 'Intention paired with aligned action.', image: 'assets/images/manifestation/cosmicodering.png'},
  ];
  return (
    <PreludeShell duration={240}>
      <MobileFrame eyebrow="Explore your toolkit" heading="Develop your inner world">
        <div style={{position: 'absolute', inset: '60px 44px 42px', display: 'flex', flexDirection: 'column'}}>
          <ProgressDots active={1} />
          <div style={{fontSize: 46, lineHeight: 1.03, fontWeight: 860, letterSpacing: -2.4, color: ink, marginTop: 46}}>Train your mind.<br />Shape your direction.</div>
          <div style={{fontSize: 23, color: muted, lineHeight: 1.4, marginTop: 17}}>Practical mobile tools for clarity, imagination and lasting change.</div>
          <div style={{display: 'grid', gap: 18, marginTop: 34}}>
            {features.map((feature, i) => {
              const p = spring({frame: frame - 18 - i * 13, fps, config: {damping: 17, stiffness: 92}});
              return <div key={feature.title} style={{height: 300, padding: 15, borderRadius: 29, background: 'white', display: 'grid', gridTemplateColumns: '1.03fr .97fr', gap: 20, border: '1px solid #E0E8E4', boxShadow: '0 15px 34px rgba(16,42,33,.08)', opacity: p, transform: `translateX(${interpolate(p,[0,1],[70,0])}px)`}}>
                <Img src={staticFile(feature.image)} style={{width: '100%', height: '100%', objectFit: 'cover', borderRadius: 20}} />
                <div style={{display: 'flex', flexDirection: 'column', justifyContent: 'center'}}>
                  <div style={{fontSize: 30, fontWeight: 830, color: ink, letterSpacing: -1}}>{feature.title}</div>
                  <div style={{fontSize: 21, color: muted, lineHeight: 1.38, marginTop: 10}}>{feature.body}</div>
                  <div style={{fontSize: 20, fontWeight: 760, color: green, marginTop: 18}}>Explore tool →</div>
                </div>
              </div>;
            })}
          </div>
          <div style={{marginTop: 'auto'}}><Button pressed={Math.abs(frame - 205) < 7}>Next</Button></div>
        </div>
      </MobileFrame>
      <SceneTap tapAt={205} />
    </PreludeShell>
  );
};

const BotIcon: React.FC<{size?: number}> = ({size = 180}) => {
  const frame = useCurrentFrame();
  const blink = frame % 82 > 74;
  return (
    <div style={{width: size, height: size, borderRadius: '50%', background: '#DDEAE4', display: 'grid', placeItems: 'center', boxShadow: '0 28px 65px rgba(0,0,0,.24)', border: '4px solid rgba(255,255,255,.65)'}}>
      <svg width={size * .64} height={size * .64} viewBox="0 0 120 120">
        <path d="M60 21V10M54 9h12" stroke={darkGreen} strokeWidth="7" strokeLinecap="round" />
        <rect x="22" y="29" width="76" height="63" rx="25" fill={darkGreen} />
        <rect x="33" y="44" width="54" height="34" rx="15" fill="#EAF8F2" />
        <circle cx="48" cy="60" r={blink ? 2 : 5} fill={darkGreen} />
        <circle cx="72" cy="60" r={blink ? 2 : 5} fill={darkGreen} />
        <path d="M49 72c7 5 15 5 22 0" stroke={darkGreen} strokeWidth="4" strokeLinecap="round" fill="none" />
        <path d="M26 75l-10 8M94 75l10 8" stroke={darkGreen} strokeWidth="7" strokeLinecap="round" />
      </svg>
    </div>
  );
};

const AiAssistantScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const icon = spring({frame: frame - 12, fps, config: {damping: 13, stiffness: 86}});
  const orbit = frame * .018;
  const bubbles = [
    ['Help me turn my goal into a plan.', '#E6EFEB'],
    ['I’ve broken it into three clear next steps.', '#DDF5EB'],
    ['Keep me accountable this week.', '#E6EFEB'],
  ];
  return (
    <PreludeShell duration={240}>
      <MobileFrame eyebrow="Your support, wherever you are" heading="Meet Diana Life Assistant">
        <div style={{position: 'absolute', inset: '60px 44px 42px', display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
          <div style={{alignSelf: 'stretch'}}><ProgressDots active={2} /></div>
          <div style={{position: 'relative', width: 240, height: 240, marginTop: 48, opacity: icon, transform: `scale(${icon})`}}>
            {[0,1,2].map((i) => {
              const angle = orbit + (i / 3) * Math.PI * 2;
              return <div key={i} style={{position: 'absolute', left: 115 + Math.cos(angle) * 135, top: 115 + Math.sin(angle) * 135, width: 15 + i * 3, height: 15 + i * 3, borderRadius: 99, background: i === 1 ? '#F1C94C' : green, boxShadow: '0 0 22px rgba(23,171,119,.45)'}} />;
            })}
            <div style={{position: 'absolute', inset: -26, borderRadius: '50%', border: '2px solid rgba(23,171,119,.18)', transform: `scale(${1 + Math.sin(frame / 12) * .04})`}} />
            <BotIcon size={240} />
          </div>
          <div style={{fontSize: 43, fontWeight: 860, color: ink, letterSpacing: -2, marginTop: 37}}>Personal AI support</div>
          <div style={{fontSize: 23, lineHeight: 1.42, color: muted, textAlign: 'center', maxWidth: 730, marginTop: 15}}>Diana uses context from your goals, tasks and habits to help you plan, reflect and get unstuck.</div>
          <div style={{display: 'grid', gap: 15, alignSelf: 'stretch', marginTop: 38}}>
          {bubbles.map(([text, background], i) => {
            const p = spring({frame: frame - 70 - i * 23, fps, config: {damping: 16, stiffness: 102}});
            const assistant = i === 1;
            return <div key={text} style={{justifySelf: assistant ? 'start' : 'end', maxWidth: 620, padding: '20px 24px', borderRadius: assistant ? '25px 25px 25px 7px' : '25px 25px 7px 25px', background, color: ink, fontSize: 22, fontWeight: assistant ? 720 : 600, lineHeight: 1.36, boxShadow: assistant ? '0 12px 26px rgba(16,42,33,.10)' : 'none', opacity: p, transform: `translateY(${interpolate(p,[0,1],[30,0])}px) scale(${.94 + p * .06})`}}>{text}</div>;
          })}
          </div>
          <div style={{fontSize: 20, color: darkGreen, lineHeight: 1.45, marginTop: 22, fontWeight: 720}}>Reflection · Planning · Accountability · Coaching</div>
          <div style={{marginTop: 'auto', alignSelf: 'stretch'}}><Button pressed={Math.abs(frame - 205) < 7}>Personalise my experience</Button></div>
        </div>
      </MobileFrame>
      <SceneTap tapAt={205} />
    </PreludeShell>
  );
};

const OnboardingDemo: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const phoneEnter = spring({frame: frame - 12, fps, config: {damping: 17, stiffness: 88}});
  const selected = frame >= 155;
  const firstPressed = Math.abs(frame - 230) < 7;
  const nextPressed = Math.abs(frame - 425) < 7;
  const startPressed = Math.abs(frame - 640) < 7;
  const slide1 = frame < 245 ? 0 : smooth(frame, [245, 276], [0, -900]);
  const slide2 = frame < 245 ? 900 : frame < 276 ? smooth(frame, [245, 276], [900, 0]) : frame < 445 ? 0 : smooth(frame, [445, 476], [0, -900]);
  const slide3 = frame < 445 ? 900 : smooth(frame, [445, 476], [900, 0]);

  return (
    <AbsoluteFill style={{fontFamily: font, overflow: 'hidden', background: 'linear-gradient(155deg, #092E24 0%, #0B6246 52%, #17AB77 130%)'}}>
      <div style={{position: 'absolute', width: 700, height: 700, borderRadius: '50%', background: 'rgba(113,235,191,.12)', right: -300, top: -280, filter: 'blur(25px)'}} />
      <div style={{position: 'absolute', width: 630, height: 630, borderRadius: '50%', background: 'rgba(255,229,154,.08)', left: -320, bottom: -260, filter: 'blur(25px)'}} />
      <Headline />
      <div
        style={{
          position: 'absolute', left: 95, top: 250, width: 890, height: 1520,
          borderRadius: 64, overflow: 'hidden', background: surface,
          border: '9px solid rgba(255,255,255,.92)', boxShadow: '0 55px 120px rgba(0,0,0,.34)',
          opacity: phoneEnter, transform: `translateY(${interpolate(phoneEnter,[0,1],[130,0])}px) scale(${0.92 + phoneEnter * .08})`,
        }}
      >
        <div style={{position: 'absolute', top: 15, left: '50%', transform: 'translateX(-50%)', width: 140, height: 28, borderRadius: 99, background: ink, zIndex: 20}} />
        <div style={{position: 'absolute', inset: 0, transform: `translateX(${slide1}px)`}}><QuestionScreen selected={selected} pressed={firstPressed} /></div>
        <div style={{position: 'absolute', inset: 0, transform: `translateX(${slide2}px)`}}><GuidanceScreen pressed={nextPressed} /></div>
        <div style={{position: 'absolute', inset: 0, transform: `translateX(${slide3}px)`}}><ActionScreen pressed={startPressed} /></div>
      </div>
      <Cursor />
      {frame >= 690 && <Success />}
    </AbsoluteFill>
  );
};

export const AbleriteInteractiveOnboarding: React.FC = () => (
  <AbsoluteFill style={{background: '#092E24'}}>
    <Sequence from={0} durationInFrames={180}><HolisticIntro /></Sequence>
    <Sequence from={180} durationInFrames={240}><FeatureTools /></Sequence>
    <Sequence from={420} durationInFrames={240}><AiAssistantScene /></Sequence>
    <Sequence from={660} durationInFrames={900}><OnboardingDemo /></Sequence>
  </AbsoluteFill>
);
