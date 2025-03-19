import { Component } from '@angular/core';
import {MatIconButton} from "@angular/material/button";
import {MatIcon} from "@angular/material/icon";
import {OAuthService} from "angular-oauth2-oidc";
import {authCodeFlowConfig} from "../auth/auth-config";

@Component({
  selector: 'app-sync-scores-button',
  imports: [
    MatIconButton,
    MatIcon
  ],
  templateUrl: './sync-scores-button.component.html',
  styleUrl: './sync-scores-button.component.scss'
})
export class SyncScoresButtonComponent {

  constructor(
    private oauthService: OAuthService
  ) {
  }

  public onClick(): Promise<boolean> {
    this.oauthService.configure(authCodeFlowConfig);
    return this.oauthService.loadDiscoveryDocumentAndLogin();
  }

}
