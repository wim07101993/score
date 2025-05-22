const template = document.createElement('template');
template.innerHTML = `
  <button>Log in to continue</button>
`

class Login extends HTMLElement {
  constructor() {
    super();

    const shadowRoot = this.attachShadow({mode: 'open'});
    shadowRoot.append(template.content.cloneNode(true));

    this.button = shadowRoot.querySelector('button')
    this.button.onclick = this.onLogIn
  }

  onLogIn() {
    console.log('log-in');
  }
}

window.customElements.define('login-button', Login)
