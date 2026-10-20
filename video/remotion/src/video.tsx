import React from 'react';
import {
  AbsoluteFill,
  Img,
  Sequence,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';

const C = {
  ink: '#102A21',
  muted: '#597067',
  green: '#17AB77',
  darkGreen: '#0B6246',
  mint: '#DDF5EB',
  cream: '#F7FAF8',
  white: '#FFFFFF',
  lilac: '#DCC6F5',
  coral: '#FFB6A3',
  yellow: '#FFE59A',
};

const font = "Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif";

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

const Scene: React.FC<React.PropsWithChildren<{duration?: number; dark?: boolean}>> = ({
  children,
  duration = 180,
  dark = false,
}) => {
  const frame = useCurrentFrame();
  const opacity = Math.min(
    interpolate(frame, [0, 18], [0, 1], clamp),
    interpolate(frame, [duration - 18, duration], [1, 0], clamp),
  );

  return (
    <AbsoluteFill
      style={{
        opacity,
        overflow: 'hidden',
        color: dark ? C.white : C.ink,
        background: dark
          ? 'linear-gradient(155deg, #092E24 0%, #0B6246 48%, #17AB77 130%)'
          : 'linear-gradient(155deg, #FBFDFC 0%, #ECF8F3 58%, #DDF5EB 100%)',
        fontFamily: font,
      }}
    >
      <Ambient dark={dark} />
      {children}
    </AbsoluteFill>
  );
};

const Ambient: React.FC<{dark: boolean}> = ({dark}) => {
  const frame = useCurrentFrame();
  const drift = Math.sin(frame / 38) * 18;
  return (
    <>
      <div
        style={{
          position: 'absolute',
          width: 720,
          height: 720,
          borderRadius: '50%',
          right: -300 + drift,
          top: -260,
          background: dark ? 'rgba(102, 232, 184, .13)' : 'rgba(23, 171, 119, .11)',
          filter: 'blur(16px)',
        }}
      />
      <div
        style={{
          position: 'absolute',
          width: 620,
          height: 620,
          borderRadius: '50%',
          left: -330 - drift,
          bottom: -260,
          background: dark ? 'rgba(255, 229, 154, .08)' : 'rgba(220, 198, 245, .18)',
          filter: 'blur(22px)',
        }}
      />
    </>
  );
};

const Brand: React.FC<{light?: boolean}> = ({light = false}) => (
  <div style={{display: 'flex', alignItems: 'center', gap: 20}}>
    <Img
      src={staticFile('assets/ablerite_logo_rounded.png')}
      style={{width: 72, height: 72, borderRadius: 19, boxShadow: '0 12px 28px rgba(0,0,0,.13)'}}
    />
    <div style={{fontSize: 38, fontWeight: 800, letterSpacing: -1.5, color: light ? C.white : C.ink}}>
      Ablerite
    </div>
  </div>
);

const Kicker: React.FC<React.PropsWithChildren<{light?: boolean}>> = ({children, light = false}) => (
  <div
    style={{
      display: 'inline-flex',
      alignItems: 'center',
      gap: 12,
      padding: '13px 20px',
      borderRadius: 999,
      background: light ? 'rgba(255,255,255,.12)' : 'rgba(23,171,119,.11)',
      border: `1px solid ${light ? 'rgba(255,255,255,.18)' : 'rgba(23,171,119,.18)'}`,
      color: light ? '#CFF9E9' : C.darkGreen,
      fontSize: 23,
      fontWeight: 750,
      letterSpacing: 1.6,
      textTransform: 'uppercase',
    }}
  >
    <span style={{width: 10, height: 10, borderRadius: 9, background: light ? '#8CF1CB' : C.green}} />
    {children}
  </div>
);

const Title: React.FC<React.PropsWithChildren<{light?: boolean; size?: number}>> = ({
  children,
  light = false,
  size = 88,
}) => (
  <div
    style={{
      fontSize: size,
      fontWeight: 850,
      lineHeight: 0.98,
      letterSpacing: -5.5,
      color: light ? C.white : C.ink,
      textWrap: 'balance',
    }}
  >
    {children}
  </div>
);

const Body: React.FC<React.PropsWithChildren<{light?: boolean}>> = ({children, light = false}) => (
  <div
    style={{
      fontSize: 33,
      lineHeight: 1.38,
      fontWeight: 480,
      color: light ? 'rgba(255,255,255,.74)' : C.muted,
      letterSpacing: -0.8,
    }}
  >
    {children}
  </div>
);

const rise = (frame: number, delay: number, fps: number) => {
  const p = spring({frame: frame - delay, fps, config: {damping: 16, stiffness: 105, mass: 0.8}});
  return {opacity: p, transform: `translateY(${interpolate(p, [0, 1], [55, 0])}px)`};
};

const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const logo = spring({frame, fps, config: {damping: 14, stiffness: 90}});
  const words = ['Clarity', 'Action', 'Momentum'];
  return (
    <Scene dark>
      <div style={{position: 'absolute', inset: '110px 80px 90px', display: 'flex', flexDirection: 'column'}}>
        <div style={{...rise(frame, 4, fps)}}><Brand light /></div>
        <div style={{marginTop: 235, ...rise(frame, 18, fps)}}>
          <Kicker light>Your life, in one place</Kicker>
        </div>
        <div style={{marginTop: 48, ...rise(frame, 28, fps)}}>
          <Title light size={104}>Build the life you keep imagining.</Title>
        </div>
        <div style={{marginTop: 46, maxWidth: 830, ...rise(frame, 42, fps)}}>
          <Body light>Ablerite brings your goals, growth, wellbeing and money together—so every day has direction.</Body>
        </div>
        <div style={{marginTop: 'auto', display: 'flex', gap: 18}}>
          {words.map((word, i) => (
            <div
              key={word}
              style={{
                ...rise(frame, 58 + i * 7, fps),
                padding: '22px 28px',
                borderRadius: 22,
                background: 'rgba(255,255,255,.10)',
                border: '1px solid rgba(255,255,255,.13)',
                fontSize: 26,
                fontWeight: 700,
              }}
            >
              {word}
            </div>
          ))}
        </div>
        <div
          style={{
            position: 'absolute',
            right: -110,
            bottom: 190,
            width: 310,
            height: 310,
            opacity: logo * 0.07,
            transform: `scale(${0.8 + logo * 0.2}) rotate(-8deg)`,
          }}
        >
          <Img src={staticFile('assets/ablerite_logo_rounded.png')} style={{width: '100%', height: '100%'}} />
        </div>
      </div>
    </Scene>
  );
};

const FocusScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const art = spring({frame: frame - 12, fps, config: {damping: 18, stiffness: 80}});
  const chips = [
    ['♥', 'Health', C.coral],
    ['↗', 'Wealth', C.yellow],
    ['◎', 'Stress', C.mint],
    ['✦', 'Purpose', C.lilac],
  ];
  return (
    <Scene>
      <div style={{position: 'absolute', inset: '105px 76px 80px'}}>
        <div style={rise(frame, 4, fps)}><Kicker>Start with what matters</Kicker></div>
        <div style={{marginTop: 38, ...rise(frame, 14, fps)}}>
          <Title>Focus your energy.</Title>
        </div>
        <div style={{marginTop: 30, maxWidth: 850, ...rise(frame, 24, fps)}}>
          <Body>Choose the part of life that needs attention. Ablerite helps you turn pressure into a clear starting point.</Body>
        </div>
        <div
          style={{
            marginTop: 60,
            height: 770,
            borderRadius: 54,
            overflow: 'hidden',
            background: C.white,
            boxShadow: '0 38px 80px rgba(16,42,33,.16)',
            opacity: art,
            transform: `translateY(${interpolate(art, [0, 1], [70, 0])}px) scale(${0.92 + art * 0.08})`,
          }}
        >
          <Img src={staticFile('assets/images/onboarding/pain_points.png')} style={{width: '100%', height: '100%', objectFit: 'cover'}} />
        </div>
        <div style={{display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 17, marginTop: 38}}>
          {chips.map(([icon, label, color], i) => (
            <div
              key={label}
              style={{
                ...rise(frame, 40 + i * 6, fps),
                display: 'flex', alignItems: 'center', gap: 18,
                padding: '20px 24px', borderRadius: 24, background: C.white,
                boxShadow: '0 14px 35px rgba(16,42,33,.07)', fontSize: 27, fontWeight: 720,
              }}
            >
              <span style={{display: 'grid', placeItems: 'center', width: 48, height: 48, borderRadius: 15, background: color, fontSize: 25}}>{icon}</span>
              {label}
            </div>
          ))}
        </div>
      </div>
    </Scene>
  );
};

const LearnScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const art = spring({frame: frame - 20, fps, config: {damping: 16, stiffness: 82}});
  return (
    <Scene dark>
      <div style={{position: 'absolute', inset: '105px 76px 90px'}}>
        <div style={rise(frame, 4, fps)}><Kicker light>Guidance that moves with you</Kicker></div>
        <div style={{marginTop: 38, ...rise(frame, 14, fps)}}><Title light>Learn in the moments you have.</Title></div>
        <div style={{marginTop: 34, maxWidth: 850, ...rise(frame, 26, fps)}}>
          <Body light>Listen, read and reflect with practical content designed to build perspective—not overwhelm.</Body>
        </div>
        <div
          style={{
            position: 'absolute', left: 76, right: 76, top: 720, height: 720,
            borderRadius: 56, overflow: 'hidden', boxShadow: '0 45px 95px rgba(0,0,0,.30)',
            opacity: art,
            transform: `translateY(${interpolate(art, [0, 1], [90, 0])}px) rotate(${interpolate(art, [0, 1], [4, -1.5])}deg)`,
          }}
        >
          <Img src={staticFile('assets/images/onboarding/free_media.png')} style={{width: '100%', height: '100%', objectFit: 'cover'}} />
        </div>
        <div style={{position: 'absolute', left: 76, right: 76, bottom: 100, display: 'flex', gap: 18}}>
          {['Audio insights', 'Courses', 'Reflection'].map((label, i) => (
            <div key={label} style={{...rise(frame, 52 + i * 6, fps), flex: 1, padding: '23px 16px', textAlign: 'center', borderRadius: 22, background: 'rgba(255,255,255,.11)', border: '1px solid rgba(255,255,255,.15)', fontSize: 23, fontWeight: 720}}>
              {label}
            </div>
          ))}
        </div>
      </div>
    </Scene>
  );
};

const PhoneCard: React.FC<{src: string; left: number; top: number; rotate: number; delay: number; width?: number}> = ({src, left, top, rotate, delay, width = 405}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame: frame - delay, fps, config: {damping: 17, stiffness: 95, mass: 0.8}});
  return (
    <div style={{position: 'absolute', left, top, width, height: width * 1.78, borderRadius: 48, overflow: 'hidden', background: C.white, boxShadow: '0 42px 90px rgba(16,42,33,.21)', border: '8px solid rgba(255,255,255,.9)', opacity: p, transform: `translateY(${interpolate(p, [0,1],[130,0])}px) rotate(${rotate}deg) scale(${0.9 + p * 0.1})`}}>
      <Img src={staticFile(src)} style={{width: '100%', height: '100%', objectFit: 'cover', objectPosition: 'top'}} />
    </div>
  );
};

const ActionScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <Scene>
      <div style={{position: 'absolute', inset: '105px 76px 80px'}}>
        <div style={rise(frame, 4, fps)}><Kicker>From insight to action</Kicker></div>
        <div style={{marginTop: 38, ...rise(frame, 14, fps)}}><Title>Make progress visible.</Title></div>
        <div style={{marginTop: 30, maxWidth: 860, ...rise(frame, 24, fps)}}>
          <Body>Set meaningful goals. Break them into next steps. Keep your plan close enough to use every day.</Body>
        </div>
        <PhoneCard src="assets/guide_images/action_goals.png" left={8} top={640} rotate={-5} delay={34} width={430} />
        <PhoneCard src="assets/guide_images/action_tasklists.png" left={475} top={785} rotate={5} delay={47} width={415} />
        <div style={{position: 'absolute', left: 34, bottom: 45, ...rise(frame, 70, fps), display: 'flex', alignItems: 'center', gap: 18, padding: '20px 27px', borderRadius: 25, background: C.ink, color: C.white, fontSize: 26, fontWeight: 750, boxShadow: '0 20px 45px rgba(16,42,33,.22)'}}>
          <span style={{display: 'grid', placeItems: 'center', width: 42, height: 42, borderRadius: 99, background: C.green}}>✓</span>
          One clear next step
        </div>
      </div>
    </Scene>
  );
};

const FinalScene: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const pulse = 1 + Math.sin(frame / 10) * 0.015;
  const items = ['Goals', 'Wellbeing', 'Money', 'Growth'];
  return (
    <Scene dark>
      <div style={{position: 'absolute', inset: '105px 76px 85px', display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center'}}>
        <div style={rise(frame, 2, fps)}><Brand light /></div>
        <div style={{marginTop: 160, ...rise(frame, 15, fps)}}><Kicker light>Your whole life, connected</Kicker></div>
        <div style={{marginTop: 45, ...rise(frame, 26, fps)}}><Title light size={98}>Less drifting.<br />More becoming.</Title></div>
        <div style={{marginTop: 42, maxWidth: 820, ...rise(frame, 38, fps)}}>
          <Body light>One calm space to decide what matters, take action, and build momentum that lasts.</Body>
        </div>
        <div style={{marginTop: 90, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, width: '100%'}}>
          {items.map((label, i) => (
            <div key={label} style={{...rise(frame, 48 + i * 7, fps), padding: '29px 20px', borderRadius: 28, background: 'rgba(255,255,255,.10)', border: '1px solid rgba(255,255,255,.15)', fontSize: 28, fontWeight: 730}}>
              <span style={{color: '#8CF1CB', marginRight: 12}}>✓</span>{label}
            </div>
          ))}
        </div>
        <div style={{marginTop: 'auto', width: '100%', ...rise(frame, 77, fps)}}>
          <div style={{transform: `scale(${pulse})`, padding: '31px 42px', borderRadius: 28, background: C.white, color: C.darkGreen, fontSize: 34, fontWeight: 840, boxShadow: '0 28px 70px rgba(0,0,0,.24)'}}>
            Start building with Ablerite
          </div>
          <div style={{marginTop: 27, fontSize: 24, color: 'rgba(255,255,255,.62)', letterSpacing: 0.4}}>Your next chapter starts with one step.</div>
        </div>
      </div>
    </Scene>
  );
};

export const AbleriteOnboarding: React.FC = () => (
  <AbsoluteFill style={{backgroundColor: C.cream}}>
    <Sequence from={0} durationInFrames={180}><Intro /></Sequence>
    <Sequence from={180} durationInFrames={180}><FocusScene /></Sequence>
    <Sequence from={360} durationInFrames={180}><LearnScene /></Sequence>
    <Sequence from={540} durationInFrames={180}><ActionScene /></Sequence>
    <Sequence from={720} durationInFrames={180}><FinalScene /></Sequence>
  </AbsoluteFill>
);
