const BaseTemplate = require('./BaseTemplate');

class ReceiptEmailTemplate extends BaseTemplate {
    getHeader({userName, courseName, authorName, orderDate, paymentMethod, total}) {
        return ` 
               <mj-section background-color="#f0f0f0" background-url="${this.getImagePath()}bg.png"
                    background-size="cover"
                    background-repeat="no-repeat">
                      <mj-column width="100%" padding="40px 20px 0px 20px">
                        <mj-image width="50px" height="50px" src="${this.getImagePath()}logo.png" align="left" padding-bottom="30px"/>
                        
                        <mj-text mj-class="headerText">Dear <span style="font-weight: 600">${userName}</span>:</mj-text>
                        <mj-text mj-class="headerSubtext">Thank you for subscribing to <span style="font-weight:600">${courseName}</span> </span> <br/>
                        workshop by <span style="font-weight:600">${authorName}</span></mj-text>
                     </mj-column>
                        <mj-column padding="0 20px 30px 20px" width="100%">
  
                          
                          
                         <mj-text mj-class="baseText" align="left" color="#fff">
                                               <span style="font-weight:600"> Order Date: ${orderDate}</span>
                                           </mj-text>
                                <mj-text mj-class="baseText" align="left" color="#fff">
                                                           <span style="font-weight:600; color: #fff!important;"> Details of payment</span>
                                                           <br/>
                                                           <span style="color:#fff!important;">Workshop name: ${courseName}<br/></span>
                                                           <span style="color:#fff!important;">Payment method: ${paymentMethod}<br/></span>
                                                           <span style="color:#fff!important;">Total: ${total}</span>
                                                       </mj-text>
                       </mj-column>
                </mj-section>
              `;
    }


    getContent() {
        return ` <mj-section padding="30px 20px">
        <mj-column>
          <mj-text mj-class="baseText" align="left" color="#4a4a4a">Don't forget to attend and ask plenty of questions at the end.<br/> Our experts love to interact with their audience.</mj-text>
          <mj-text mj-class="baseText" align="left" color="#4a4a4a">If you have any questions or suggestions on how we can make your<br/> experience better, please contact us at <a href="mailto:info@troovyapp.com" class="link" style="color:#524cfc!important; fo
nt-weight: 600!important; text-decoration: none!important;">info@troovyapp.com</a>.</mj-text>
          <mj-text mj-class="baseText" align="left" color="#4a4a4a">On behalf of all of us at Troovy, thank you for your purchase. <br/> We really appreciate it.</mj-text>
          <mj-text mj-class="baseText" align="left" color="#4a4a4a" padding-bottom="36px">Yours truly, <br/>Troovy Team</mj-text>
        </mj-column>
      </mj-section>`;
    }

    render(options) {
        const content = this.getContent(options);
        const header = this.getHeader(options);
        return this.renderTemplate(content, header);
    }
}

module.exports = new ReceiptEmailTemplate();
