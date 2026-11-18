import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { ApiConfig, Log } from '@cloudmusic/commons';
import { window } from '@kit.ArkUI';
import { PlayerService } from '@cloudmusic/player';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    ApiConfig.loadDevelopmentCertificate(this.context);
    PlayerService.attach(this.context);
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    Log.info('Ability', 'Created');
  }

  onDestroy(): void {
    PlayerService.detach(this.context);
    Log.info('Ability', 'Destroyed');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    const started = Date.now();

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Log.error('Ability', 'Window content failed: ' + err.code.toString());
        return;
      }
      Log.info('Ability', 'Window content loaded, elapsed ms=' + (Date.now() - started).toString());
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    Log.info('Ability', 'Window destroyed');
  }

  onForeground(): void {
    // Ability has brought to foreground
    Log.info('Ability', 'Foreground');
  }

  onBackground(): void {
    // Ability has back to background
    Log.info('Ability', 'Background');
  }
}