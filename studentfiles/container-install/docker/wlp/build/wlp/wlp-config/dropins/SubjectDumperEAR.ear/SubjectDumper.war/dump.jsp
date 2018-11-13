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
			sb.append("{");
			sb.append("Number of " + title + ": ");
			sb.append(s.size());
			sb.append(" ");

			sbhtml.append("<table border=\"1\">");
			sbhtml.append("<tr><th colspan=\"4\">" + title + " ("+s.size()+")</th></tr>");
			sbhtml.append("<tr><th>Index</th><th>Class Name</th><th>toString()</th><th>Details</th></tr>");
			int j = 0;

			for (Iterator i = s.iterator(); i.hasNext();) {
				sb.append("{");
				Object o = i.next();
				sb.append("ClassOf" + title + "=");
				sb.append(o.getClass().getName());
				sb.append(",toString=");
				sb.append(o.toString());
				sb.append(",");

				sbhtml.append("<tr><td>" + j + "</td><td>" + htmlEncode(o.getClass().getName()) + "</td><td>"+ htmlEncode(o.toString()) + "</td><td>");
				j++;

				if (o instanceof Token) {
					Token t = (Token) o;
					dumpTokenDetails(t, sb, sbhtml);
				} else if (o instanceof WSCredential) {
					WSCredential cred = (WSCredential) o;
					try {
						dumpCredentialDetails(cred, sb, sbhtml);
					} catch (Exception e) {
						sb.append("Error getting credential details");
						sbhtml.append("Error getting credential details");
					}
				} else if (o instanceof Saml20Token) {
			          Saml20Token samlToken = (Saml20Token) o;
			          dumpSAMLToken(samlToken, sb, sbhtml);
				} else {
					sb.append("No details for this class");
					sbhtml.append("No details for this class");
				}

				sb.append("}");
				sbhtml.append("</td></tr>");
			}
			sb.append("}");
			sbhtml.append("</table><br />");
		} else {
			sb.append("{" + title + " set is null}");
			sbhtml.append(title + " set is null<br />");
		}
    }

    void dumpTokenDetails(Token t, StringBuffer sb, StringBuffer sbhtml) {
    	if (t != null) {
	    	sb.append("{");
	    	sbhtml.append("<table border=\"1\">");
	    	sbhtml.append("<tr><th>Method</th><th>Results</th></tr>");

	    	sb.append("Name="+t.getName());
	    	sb.append(",Principal="+t.getPrincipal());
	    	sb.append(",Expiration="+t.getExpiration());
	    	sb.append(",UniqueID="+t.getUniqueID());
	    	sb.append(",Version="+t.getVersion());
	    	sb.append(",IsForwardable="+t.isForwardable());
	    	sb.append(",IsValid="+t.isValid());

	    	sbhtml.append("<tr><td>getName()</td><td>" + htmlEncode(t.getName()) + "</td></tr>");
	    	sbhtml.append("<tr><td>getPrincipal()</td><td>" + t.getPrincipal() + "</td></tr>");
	    	sbhtml.append("<tr><td>getExpiration()</td><td>" + t.getExpiration() + "</td></tr>");
	    	sbhtml.append("<tr><td>getUniqueID()</td><td>" + htmlEncode(t.getUniqueID()) + "</td></tr>");
	    	sbhtml.append("<tr><td>getVersion()</td><td>" + t.getVersion() + "</td></tr>");
	    	sbhtml.append("<tr><td>isForwardable()</td><td>" + t.isForwardable() + "</td></tr>");
	    	sbhtml.append("<tr><td>isValid()</td><td>" + t.isValid() + "</td></tr>");

	    	sb.append(",Attributes={");
	    	sbhtml.append("<tr><td>Attributes</td><td>");

	    	sbhtml.append("<table border=\"1\">");
	    	sbhtml.append("<tr><th>Name</th><th>Values</th></tr>");
	    	if (t.getAttributeNames() != null) {
				for (Enumeration attributesNames = t.getAttributeNames(); attributesNames.hasMoreElements(); ) {
					String attrName = (String) attributesNames.nextElement();
					String[] attrValues = t.getAttributes(attrName);

					sb.append(attrName);
					sb.append(": [");

					sbhtml.append("<tr><td>" + htmlEncode(attrName) + "</td><td>");

					sbhtml.append("<table border=\"1\">");
					if (attrValues != null) {
						for (int x = 0; x < attrValues.length; x++) {
							sb.append(attrValues[x]);
							if (x < (attrValues.length-1)) {
								sb.append(", ");
							}

							sbhtml.append("<tr><td>"+htmlEncode(attrValues[x])+"</td></tr>");

						}
					}
					sbhtml.append("</table>");

					sb.append("]");
					sbhtml.append("</td>");

					if (attributesNames.hasMoreElements()) {
						sb.append(", ");
					}
				}
			}
			sbhtml.append("</table>");


			sb.append("}");
			sbhtml.append("</td></tr>");


			sb.append("}");
	    	sbhtml.append("</table>");
	    } else {
	    	sb.append ("{}");
	    	sbhtml.append("<table />");
	    }
    }

    void dumpSAMLToken(Saml20Token t, StringBuffer sb, StringBuffer sbhtml) {
    	if (t != null) {
	    	sb.append("{");
	    	sbhtml.append("<table border=\"1\">");
	    	sbhtml.append("<tr><th>Method</th><th>Results</th></tr>");

	    	sb.append("Issuer="+t.getSAMLIssuerName());
	    	sb.append(",IssueInstant="+t.getIssueInstant());
	    	sb.append(",NameID="+t.getSAMLNameID());

	    	sbhtml.append("<tr><td>getSAMLIssuerName()</td><td>" + htmlEncode(t.getSAMLIssuerName()) + "</td></tr>");
	    	sbhtml.append("<tr><td>getIssueInstant()</td><td>" + t.getIssueInstant() + "</td></tr>");
	    	sbhtml.append("<tr><td>getSAMLNameID()</td><td>" + htmlEncode(t.getSAMLNameID()) + "</td></tr>");

	    	if (t.getSAMLAttributes() != null && t.getSAMLAttributes().size() > 0) {
		    	sb.append(",Attributes={");
		    	sbhtml.append("<tr><td>Attributes</td><td>");

		    	sbhtml.append("<table border=\"1\">");
		    	sbhtml.append("<tr><th>Name</th><th>Values</th></tr>");

	    		List<Saml20Attribute> attrList = t.getSAMLAttributes();
				for (int y = 0; y < attrList.size(); y++) {
					String attrName = (String) attrList.get(y).getName();
					List<String> attrValues = attrList.get(y).getValuesAsString();

					sb.append(attrName);
					sb.append(": [");

					sbhtml.append("<tr><td>" + htmlEncode(attrName) + "</td><td>");

					sbhtml.append("<table border=\"1\">");
					if (attrValues != null) {
						for (int x = 0; x < attrValues.size(); x++) {
							sb.append(attrValues.get(x));
							if (x < (attrValues.size()-1)) {
								sb.append(", ");
							}

							sbhtml.append("<tr><td>"+htmlEncode(attrValues.get(x))+"</td></tr>");

						}
					}
					sbhtml.append("</table>");

					sb.append("]");
					sbhtml.append("</td>");

					if (y < (attrList.size()-1)) {
						sb.append(", ");
					}
				}
				sbhtml.append("</table>");
	    	}



			sb.append("}");
			sbhtml.append("</td></tr>");


			sb.append("}");
	    	sbhtml.append("</table>");
	    } else {
	    	sb.append ("{}");
	    	sbhtml.append("<table />");
	    }
    }


    void dumpCredentialDetails(WSCredential c, StringBuffer sb, StringBuffer sbhtml) throws Exception {
    	sb.append("{");
    	sbhtml.append("<table border=\"1\">");
    	sbhtml.append("<tr><th>Method</th><th>Results</th></tr>");

    	sb.append("AccessId="+c.getAccessId());
    	sb.append(",Expiration="+c.getExpiration());
    	//sb.append(",HostName="+c.getHostName());
    	sb.append(",OID="+c.getOID());
    	sb.append(",PrimaryGroupId="+c.getPrimaryGroupId());
    	sb.append(",RealmName="+c.getRealmName());
    	sb.append(",RealmSecurityName="+c.getRealmSecurityName());
    	sb.append(",RealmUniqueSecurityName="+c.getRealmUniqueSecurityName());
    	sb.append(",SecurityName="+c.getSecurityName());
    	sb.append(",UniqueSecurityName="+c.getUniqueSecurityName());
    	sb.append(",GroupIds="+c.getGroupIds());
    	//sb.append(",Roles="+c.getRoles());
    	sb.append(",IsBasicAuth="+c.isBasicAuth());
    	//sb.append(",IsCurrent="+c.isCurrent());
    	//sb.append(",IsDestroyed="+c.isDestroyed());
    	sb.append(",IsForwardable="+c.isForwardable());
    	sb.append(",IsUnauthenticated="+c.isUnauthenticated());

    	sbhtml.append("<tr><td>getAccessId()</td><td>" + htmlEncode(c.getAccessId()) + "</td></tr>");
    	sbhtml.append("<tr><td>getExpiration()</td><td>" + c.getExpiration() + "</td></tr>");
    	//sbhtml.append("<tr><td>getHostName()</td><td>" + htmlEncode(c.getHostName()) + "</td></tr>");
    	sbhtml.append("<tr><td>getOID()</td><td>" + htmlEncode(c.getOID()) + "</td></tr>");
    	sbhtml.append("<tr><td>getPrimaryGroupId()</td><td>" + htmlEncode(c.getPrimaryGroupId()) + "</td></tr>");
    	sbhtml.append("<tr><td>getRealmName()</td><td>" + htmlEncode(c.getRealmName()) + "</td></tr>");
    	sbhtml.append("<tr><td>getRealmSecurityName()</td><td>" + htmlEncode(c.getRealmSecurityName()) + "</td></tr>");
    	sbhtml.append("<tr><td>getRealmUniqueSecurityName()</td><td>" + htmlEncode(c.getRealmUniqueSecurityName()) + "</td></tr>");
    	sbhtml.append("<tr><td>getSecurityName()</td><td>" + htmlEncode(c.getSecurityName()) + "</td></tr>");
    	sbhtml.append("<tr><td>getUniqueSecurityName()</td><td>" + htmlEncode(c.getUniqueSecurityName()) + "</td></tr>");
    	sbhtml.append("<tr><td>getGroupIds()</td><td>" + htmlEncode(c.getGroupIds().toString()) + "</td></tr>");
    	//sbhtml.append("<tr><td>getRoles()</td><td>" + htmlEncode(c.getRoles().toString()) + "</td></tr>");
    	sbhtml.append("<tr><td>isBasicAuth()</td><td>" + c.isBasicAuth() + "</td></tr>");
    	//sbhtml.append("<tr><td>isCurrent()</td><td>" + c.isCurrent() + "</td></tr>");
    	//sbhtml.append("<tr><td>isDestroyed()</td><td>" + c.isDestroyed() + "</td></tr>");
    	sbhtml.append("<tr><td>isForwardable()</td><td>" + c.isForwardable() + "</td></tr>");
    	sbhtml.append("<tr><td>isUnauthenticated()</td><td>" + c.isUnauthenticated() + "</td></tr>");

		sb.append("}");
    	sbhtml.append("</table>");
    }
%>

<%
	Subject s = WSSubject.getCallerSubject();

	// dump the subject contents to a string buffer
	StringBuffer sb = new StringBuffer();
	StringBuffer sbhtml = new StringBuffer();
	sb.append("[");
	sbhtml.append("<div>");
	if (s != null) {
		// principals
		Set principalSet = s.getPrincipals();
		if (principalSet != null) {
			sb.append("{");
			sb.append("Number of principals: ");
			sb.append(principalSet.size());
			sbhtml.append("<table border=\"1\">");
			sbhtml.append("<tr><th colspan=\"2\">Principals ("+principalSet.size()+")</th></tr>");
			sbhtml.append("<tr><th>Index</th><th>Principal Name</th></tr>");
			int j=0;
			for (Iterator i = principalSet.iterator(); i.hasNext();) {
				sb.append("{");
				sbhtml.append("<tr><td>" + j + "</td><td>");
				Principal p = (Principal) i.next();
				j++;
				sb.append("Name=");
				sb.append(p.getName());
				sbhtml.append(p.getName());
				sb.append("}");
				sbhtml.append("</td></tr>");
			}
			sb.append("}");
			sbhtml.append("</table><br />");
		} else {
			sb.append("{Principal set is null}");
		}

		// private credentials
		Set privateCredentialSet = s.getPrivateCredentials();
		dumpCredentialSet(privateCredentialSet, "privateCredentials", sb, sbhtml);

		// public credentials
		Set publicCredentialSet = s.getPublicCredentials();
		dumpCredentialSet(publicCredentialSet, "publicCredentials", sb, sbhtml);
	}

	sb.append("]");
	sbhtml.append("</div>");
%>
</head>
<body>
<div>
<%
	HttpSession sess = request.getSession();
	String sessQS = (String) sess.getAttribute("QS");
	if (sessQS == null) {
		sessQS = "";
	}
	String newQS = request.getQueryString();
	if (newQS != null) {
		sess.setAttribute("QS", newQS);
	} else {
		newQS = "";
	}
 %>
Existing session query string: <%=htmlEncode(sessQS) %>
<br/>
Request query string put in session: <%=htmlEncode(newQS) %>
<hr/>
</div>
<h1>Subject Details</h1>
<pre>
<%=sb.toString()%>
</pre>
<%=sbhtml.toString()%>
</body>
</html>
