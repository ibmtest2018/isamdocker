<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    session="true"
    import="java.util.Enumeration"
    import="java.util.Iterator"
    import="java.util.Set"
    import="java.util.List"
    import="java.util.StringTokenizer"
    import="javax.security.auth.Subject"
	import="java.security.Principal"
    import="com.ibm.websphere.security.auth.WSSubject"
	import="com.ibm.websphere.security.cred.WSCredential"
    import="com.ibm.wsspi.security.token.Token"
    import="com.ibm.websphere.security.saml2.Saml20Token"
    import="com.ibm.websphere.security.saml2.Saml20Attribute"
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Pragma" content="no-cache">
<title>Dump the User's Subject</title>
<%!
    /**
     * Html-encode to guard against CSS and/or SQL injection attacks
     * @param pText string that may contain special characters like &, <, >, "
     * @return encoded string with offending characters replaced with innocuous content
     * like <code>&amp</code>, <code>&gt</code>, <code>&lt</code> or <code>&quot</code>.
     */
    String htmlEncode(String pText)
    {
    	String result = null;
    	if (pText != null) {
	        StringTokenizer tokenizer = new StringTokenizer(pText, "&<>\"", true);
	        int tokenCount = tokenizer.countTokens();

	        /* no encoding's needed */
	        if (tokenCount == 1)
	            return pText;

	        /*
	         * text.length + (tokenCount * 6) gives buffer large enough so no
	         * addition memory would be needed and no costly copy operations would
	         * occur
	         */
	        StringBuffer buffer = new StringBuffer(pText.length() + tokenCount * 6);
	        while (tokenizer.hasMoreTokens()) {
	            String token = tokenizer.nextToken();
	            if (token.length() == 1) {
	                switch (token.charAt(0)) {
	                case '&':
	                    buffer.append("&amp;");
	                    break;
	                case '<':
	                    buffer.append("&lt;");
	                    break;
	                case '>':
	                    buffer.append("&gt;");
	                    break;
	                case '"':
	                    buffer.append("&quot;");
	                    break;
	                default:
	                    buffer.append(token);
	                }
	            } else {
	                buffer.append(token);
	            }
	        }
	        result = buffer.toString();
	    }
	    return result;
    }

    void dumpCredentialSet(Set s, String title, StringBuffer sb, StringBuffer sbhtml) {
    	if (s != null) {
    		boolean found = false;
    		for (Iterator i = s.iterator(); i.hasNext();) {
				Object o = i.next();

		        if (o instanceof Saml20Token) {
		        	  found = true;
			          Saml20Token samlToken = (Saml20Token) o;
			          dumpSAMLToken(samlToken, sb, sbhtml);
				}
			}
			if (!found) {
				sbhtml.append("No SAML Credential Found<br />");
			}
		} else {
			sbhtml.append(title + " set is null<br />");
		}
    }

     void listTable(String name, List<String> l, StringBuffer sbhtml) {
    	 if (l != null && l.size() > 0) {
    		 sbhtml.append("<tr><td>" + name + "</td><td>");
    		 sbhtml.append("<table border=\"0\">");
  			 for (int x = 0; x < l.size(); x++) {
				sbhtml.append("<tr><td>"+htmlEncode(l.get(x))+"</td></tr>");
			 }
			sbhtml.append("</table>");
			sbhtml.append("</td>");
    	 }
     }

     void dumpSAMLToken(Saml20Token t, StringBuffer sb, StringBuffer sbhtml) {
    	if (t != null) {
	    	sbhtml.append("<table border=\"1\">");
	    	sbhtml.append("<tr><th>Method</th><th>Results</th></tr>");

	    	sb.append(htmlEncode(t.getSAMLAsString().replaceAll("(.{150})", "$1%%BR%%")));

	    	sbhtml.append("<tr><td>getSamlID()</td><td>" + htmlEncode(t.getSamlID()) + "</td></tr>");
	    	sbhtml.append("<tr><td>getSAMLIssuerName()</td><td>" + htmlEncode(t.getSAMLIssuerName()) + "</td></tr>");
	    	sbhtml.append("<tr><td>getSAMLIssuerNameFormat()</td><td>" + htmlEncode(t.getSAMLIssuerNameFormat()) + "</td></tr>");
	    	sbhtml.append("<tr><td>getIssueInstant()</td><td>" + t.getIssueInstant() + "</td></tr>");
	    	sbhtml.append("<tr><td>getSamlExpires()</td><td>" + t.getSamlExpires() + "</td></tr>");
	    	sbhtml.append("<tr><td>getSAMLNameID()</td><td>" + htmlEncode(t.getSAMLNameID()) + "</td></tr>");
	    	sbhtml.append("<tr><td>getSAMLNameIDFormat()</td><td>" + htmlEncode(t.getSAMLNameIDFormat()) + "</td></tr>");
	    	sbhtml.append("<tr><td>getAuthenticationMethod()</td><td>" + htmlEncode(t.getAuthenticationMethod()) + "</td></tr>");
	    	listTable("getAudienceRestriction()", t.getAudienceRestriction(), sbhtml);
			listTable("getConfirmationMethod()", t.getConfirmationMethod(), sbhtml);
			if (t.getSAMLAttributes() != null && t.getSAMLAttributes().size() > 0) {
		    	sbhtml.append("<tr><td>Attributes</td><td>");

		    	sbhtml.append("<table border=\"1\">");
		    	sbhtml.append("<tr><th>Name</th><th>Values</th></tr>");

	    		List<Saml20Attribute> attrList = t.getSAMLAttributes();
				for (int y = 0; y < attrList.size(); y++) {
					String attrName = (String) attrList.get(y).getName();
					List<String> attrValues = attrList.get(y).getValuesAsString();

					sbhtml.append("<tr><td>" + htmlEncode(attrName) + "</td><td>");

					sbhtml.append("<table border=\"0\">");
					if (attrValues != null) {
						for (int x = 0; x < attrValues.size(); x++) {
							sbhtml.append("<tr><td>"+htmlEncode(attrValues.get(x))+"</td></tr>");
						}
					}
					sbhtml.append("</table>");

					sbhtml.append("</td>");
				}
				sbhtml.append("</table>");
	    	}

			sbhtml.append("</td></tr>");

	    	sbhtml.append("</table>");
	    } else {
	    	sb.append("{}");
	    	sbhtml.append("<table />");
	    }
    }
 %>

<%
	Subject s = WSSubject.getCallerSubject();

	// dump the subject contents to a string buffer
	StringBuffer sb = new StringBuffer();
	StringBuffer sbhtml = new StringBuffer();

	sbhtml.append("<div>");
	if (s != null) {
		// private credentials
		Set privateCredentialSet = s.getPrivateCredentials();
		dumpCredentialSet(privateCredentialSet, "privateCredentials", sb, sbhtml);
	}

	sbhtml.append("</div>");

    String sout  = sb.toString().replaceAll("%%BR%%", "<br/>");
%>
</head>
<body>
<h1>SAML Token from Subject</h1>
<%=sbhtml.toString()%>
<button onclick="myFunction()">Show SAML</button>

<div style="display:none" id="myDIV">
<pre>
<%=sout%>
</pre>
</div>
</body>
<script>
function myFunction() {
    var x = document.getElementById("myDIV");
    if (x.style.display === "none") {
        x.style.display = "block";
    } else {
        x.style.display = "none";
    }
} </script>
</html>
