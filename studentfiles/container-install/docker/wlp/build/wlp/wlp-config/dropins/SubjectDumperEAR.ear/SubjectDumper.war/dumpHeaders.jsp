<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    session="false"
    import="java.util.Enumeration"
    import="java.util.Iterator"
    import="java.util.StringTokenizer"
    import="java.util.List"
    import="java.util.ListIterator"
    import="java.util.ArrayList"
%>
<%! 
	/**
	 * Html-encode to guard against CSS and/or SQL injection attacks
	 * 
	 * @param pText
	 *            string that may contain special characters like &, <, >, "
	 * @return encoded string with offending characters replaced with innocuous
	 *         content like <code>&amp</code>, <code>&gt</code>,
	 *         <code>&lt</code> or <code>&quot</code>.
	 */
	String htmlEncode(String pText) {
		String result = null;
		if (pText != null) {
			StringTokenizer tokenizer = new StringTokenizer(pText, "&<>\"",
					true);
			int tokenCount = tokenizer.countTokens();

			/* no encoding's needed */
			if (tokenCount == 1)
				return pText;

			/*
			 * text.length + (tokenCount * 6) gives buffer large enough so no
			 * addition memory would be needed and no costly copy operations
			 * would occur
			 */
			StringBuffer buffer = new StringBuffer(pText.length() + tokenCount
					* 6);
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
	
	String listToHTMLString(List<String> stringList) {
		StringBuffer sb = new StringBuffer();
		if (stringList != null) {
			if (stringList.size() == 1) {
				sb.append(htmlEncode(stringList.get(0)));
			} else {
				// display as array
				int index = 0;
				for (ListIterator<String> li = stringList.listIterator(); li.hasNext(); ) {
					String s = li.next();
					sb.append("[" + index + "]: ");
					sb.append(htmlEncode(s));
					sb.append("<br />");
					index++;
				}
			}
		} 
		return sb.toString();
	}
	
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Pragma" content="no-cache">
<title>Dump the Request Headers</title>
</head>
<body>
<h1>Request Headers</h1>
<table>
<tr><th>Header Name</th><th>Header Values</th>
<%
	for (Enumeration<String> headerNames = request.getHeaderNames(); headerNames.hasMoreElements();) {
		String headerName = headerNames.nextElement();
		List<String> headerValsList = new ArrayList<String>();
		for (Enumeration<String> headerVals = request.getHeaders(headerName); headerVals.hasMoreElements();) {
			String headerVal = headerVals.nextElement();
			headerValsList.add(headerVal);
		}
%>
<tr><td><%=htmlEncode(headerName)%></td><td><%=listToHTMLString(headerValsList) %></td></tr>
<%		
	}
%>
</table>
</body>
</html>