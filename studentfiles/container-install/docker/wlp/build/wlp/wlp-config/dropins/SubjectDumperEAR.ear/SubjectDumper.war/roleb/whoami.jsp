<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    import="java.util.Enumeration"
    import="java.util.Iterator"
    import="java.util.Set"
    import="java.util.StringTokenizer"
    import="javax.security.auth.Subject"
	import="java.security.Principal"
    import="com.ibm.websphere.security.auth.WSSubject"
	import="com.ibm.websphere.security.cred.WSCredential"
    import="com.ibm.wsspi.security.token.Token"
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Pragma" content="no-cache">
<title>ROLE B Subject</title>
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
        
    void dumpTokenDetails(Token t, StringBuffer sbhtml) {
    	if (t != null) {
	    	sbhtml.append("<table border=\"1\">");
	    	sbhtml.append("<tr><th>Method</th><th>Results</th></tr>");
		    	
	    	sbhtml.append("<tr><td>getName()</td><td>" + htmlEncode(t.getName()) + "</td></tr>");
	    	sbhtml.append("<tr><td>getPrincipal()</td><td>" + t.getPrincipal() + "</td></tr>");
	    	sbhtml.append("<tr><td>getExpiration()</td><td>" + t.getExpiration() + "</td></tr>");
	    	sbhtml.append("<tr><td>getUniqueID()</td><td>" + htmlEncode(t.getUniqueID()) + "</td></tr>");
	    	sbhtml.append("<tr><td>getVersion()</td><td>" + t.getVersion() + "</td></tr>");
	    	sbhtml.append("<tr><td>isForwardable()</td><td>" + t.isForwardable() + "</td></tr>");
	    	sbhtml.append("<tr><td>isValid()</td><td>" + t.isValid() + "</td></tr>");
	
	    	sbhtml.append("<tr><td>Attributes</td><td>");
	    	
	    	sbhtml.append("<table border=\"1\">");
	    	sbhtml.append("<tr><th>Name</th><th>Values</th></tr>");
	    	if (t.getAttributeNames() != null) {
				for (Enumeration attributesNames = t.getAttributeNames(); attributesNames.hasMoreElements(); ) {
					String attrName = (String) attributesNames.nextElement();
					String[] attrValues = t.getAttributes(attrName);
				
					sbhtml.append("<tr><td>" + htmlEncode(attrName) + "</td><td>");
		
					sbhtml.append("<table border=\"1\">");
					if (attrValues != null) {
						for (int x = 0; x < attrValues.length; x++) {
							sbhtml.append("<tr><td>"+htmlEncode(attrValues[x])+"</td></tr>");
						}
					}
					sbhtml.append("</table>");
					
					sbhtml.append("</td>");
				}
			}
			sbhtml.append("</table>");
			sbhtml.append("</td></tr>");
	    	sbhtml.append("</table>");
	    } else {
	    	sbhtml.append("<table />");
	    }
    }
    
    String getPrincipalName(Subject s) {
    	String result = null;
    	Set principalSet = s.getPrincipals();
    	if (principalSet != null && principalSet.size() > 0) {
    		Principal p = (Principal) principalSet.iterator().next();
    		result = p.getName();
    	}
    	return result;
    }
    
    Token findTokenOfClass(Set credentialSet, String className) {
    	Token result = null;
    	if (credentialSet != null) {
    		for (Iterator i = credentialSet.iterator(); i.hasNext() && result == null;) {
    			Object o = i.next();
    			if (o instanceof Token && className.equals(o.getClass().getName())) {
    				result = (Token) o;
    			}
    		}
    	}
    	return result;
    }
%>

<%
	Subject s = WSSubject.getCallerSubject();
	
	if (s == null) {
		// trouble
		throw new Exception("Not authenticated");
	}
	
	// get the username from the first available principal
	String username = getPrincipalName(s);
	
	/* 
	* Based on the type of authentication that has been performed (LTPA, iv-creds TAI, JWT TAI)
	* there should be a "Token" in the credentials of the subject of one of these types. If you
	* already know what type of authentication is happening, you could jump straight to that 
	* method.
	*
	* For JWT TAI, look for a SimpleJWT in public credentials
	
	* For iv-creds TAI, look for a ISAMAttrsToken in public credentials.
	*
	* For LTPA, look for a SingleSignOnToken in private credentials. This will also exist for
	* the other mechanisms but won't contain all the extended attributes, so it's important
	* to look for this one last if there is more than one SSO capability in place.
	*
	* This JSP just looks for them in order until it finds one, then dumps all the attributes
	* in that token to the response as HTML.
	*/
	Set publicCredentialSet = s.getPublicCredentials();
	Set privateCredentialSet = s.getPrivateCredentials();
	
	Token t = findTokenOfClass(publicCredentialSet, "com.ibm.demo.liberty.proxytai.impl.simplejwt.SimpleJWT");
	if (t == null) {
		t = findTokenOfClass(publicCredentialSet, "com.ibm.demo.liberty.proxytai.impl.isam.ISAMAttrsToken");
	}
	if (t == null) {
		t = findTokenOfClass(privateCredentialSet, "com.ibm.ws.security.token.internal.SingleSignonTokenImpl");
	}
	
	if (t == null) {
		// trouble
		throw new Exception("Unable to find token in credentials");
	}
	
	
	// dump the html version of token contents to a string buffer
	StringBuffer sbhtml = new StringBuffer();
	sbhtml.append("<div>");
	sbhtml.append("Username: " + htmlEncode(username));
	sbhtml.append("</div>");
	sbhtml.append("<div>");
	dumpTokenDetails(t, sbhtml);
	sbhtml.append("</div>");
%>
</head>
<body>
<h1>Subject details - Role B</h1>
<%=sbhtml.toString()%>
</body>
</html>
