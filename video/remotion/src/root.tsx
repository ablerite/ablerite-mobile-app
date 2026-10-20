import React from 'react';
import {Composition} from 'remotion';
import {AbleriteOnboarding} from './video';
import {AbleriteInteractiveOnboarding} from './interactive';

export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="AbleriteInteractiveOnboarding"
      component={AbleriteInteractiveOnboarding}
      durationInFrames={1560}
      fps={30}
      width={1080}
      height={1920}
    />
    <Composition
      id="AbleriteOnboarding"
      component={AbleriteOnboarding}
      durationInFrames={900}
      fps={30}
      width={1080}
      height={1920}
    />
  </>
);
