const mjml2html = require('mjml');
const moment = require('moment');

const config = require('../../../config');

class BaseTemplate {
    getImagePath() {
        return `${config.instanceURL}/static/assets/`;
    }

    getFrontendURL() {
        return config.frontendURL;
    }

    renderHead() {
        return `<mj-head>
    <mj-attributes>
      <mj-section padding="0px"></mj-section>
      <mj-all font-size="100%" font-family="OpenSans, sans-serif"></mj-all>
      <mj-class name="header" letter-spacing="0.7px" font-size="2.3rem" font-weight="300"></mj-class>
      <mj-class nmae="bold" font-weight="600"></mj-class>
      <mj-class name="baseText" font-size="1rem" line-height="1.5" font-weight="00"></mj-class>
      <mj-class name="footerText" color="a4b0bf"></mj-class>
      <mj-class name="headerText" color="#fff" font-size="1.8rem" font-weight="300"></mj-class>
      <mj-class name="headerSubtext" color="#fff" font-size="1rem" line-height="1.4rem" font-weight="300"></mj-class>
      <mj-class name="splash" min-height="600px"></mj-class>
    </mj-attributes>
    <mj-style>.accent{ color: #524cfc; } .link{text-decoration:none; color: rgb(105 0 255); font-weight:600;} .footerText{color: #a4b0bf;} .goToButton{border-radius: 4px;padding: .7rem 4.8rem;background-color:#00d8e8;color: #ffffff;} .splash{min-height:600px;}</mj-style>
  </mj-head>`;
    }

    renderHeader() {
        return `<mj-section>
                    <mj-column>
                        <mj-image width="94" height="84" align="center" src="${this.getImagePath()}logo.png" href="${this.getFrontendURL()}">
                        </mj-image>
                    </mj-column>
                </mj-section>
              `;
    }

    renderFooter() {
        return `<mj-section mj-class="footer" background-color="#f4f6f9" padding="2rem 0 2.4rem 0" full-width="full-width">
                    <mj-column width="40%">
                        <mj-text font-size=".9rem" align="left">
                            <a class="link footerText" href="mailto:info@troovyapp.com" target="_blank">info@troovyapp.com</a>
                        </mj-text>
                    </mj-column>
                    <mj-column width="60%">
                        <mj-text mj-class="footerText" font-size=".9rem" align="right">
                            © ${moment().format('YYYY')} Troovy, All rights reserved
                        </mj-text>
                    </mj-column>
                </mj-section>`;
    }

    renderTemplate(content = '', header = '') {
        const htmlOutput = mjml2html(`
                            <mjml>
                            ${this.renderHead()}
                                <mj-body background-color="#ffffff" width="800px" padding-bottom="50px">
                                       <mj-wrapper background-color="#f0f0f0" padding="0px">
                                            ${header ? header : this.renderHeader()}
                                            ${content}
                                        </mj-wrapper>
                                </mj-body>
                            </mjml>
                        `);
        console.log(`errors during rendering email ${JSON.stringify(htmlOutput.errors)}`);
        return htmlOutput.html;
    }

    render() {
        throw Error('You have to implement the method render!');
    }
}

module.exports = BaseTemplate;
