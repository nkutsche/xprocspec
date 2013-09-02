<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step name="main" type="pxi:document" xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" version="1.0" xmlns:pxi="http://www.daisy.org/ns/xprocspec/xproc-internal/" exclude-inline-prefixes="#all"
    xpath-version="2.0" xmlns:x="http://www.daisy.org/ns/xprocspec">

    <p:input port="document" primary="true"/>
    <p:input port="description"/>
    <p:output port="result" sequence="true"/>
    <p:option name="logfile" select="''"/>

    <p:import href="../utils/load.xpl"/>
    <p:import href="../utils/recursive-directory-list.xpl"/>
    <p:import href="../utils/logging-library.xpl"/>

    <p:variable name="type" select="/*/@type"/>

    <p:variable name="temp-dir" select="/*/@temp-dir">
        <p:pipe port="description" step="main"/>
    </p:variable>
    <p:variable name="base-uri" select="if (/*/@base-uri=('temp-dir')) then /*/@base-uri else ''"/>
    <p:variable name="base-dir" select="if ($base-uri='temp-dir') then $temp-dir else replace(base-uri(/*),'^(.*/)[^/]*$','$1')"/>

    <p:variable name="port" select="/*/@port"/>
    <p:variable name="href" select="resolve-uri(/*/@href, $base-dir)"/>
    <p:variable name="method" select="if (/*/@method=('xml','html','text','binary')) then /*/@method else 'xml'"/>
    <p:variable name="recursive" select="if (/*/@recursive=('true','false')) then /*/@recursive else 'false'"/>
    
    
    <p:identity>
        <p:input port="source">
            <p:pipe step="main" port="description"/>
        </p:input>
    </p:identity>
    <p:choose>
        <p:when test="$type='port'">
            <p:variable name="position" select="if (/*/@position=('all','last') or matches(/*/@position,'\d+')) then /*/@position else 'all'">
                <p:pipe port="document" step="main"/>
            </p:variable>
            <p:filter name="port">
                <p:with-option name="select" select="concat('/x:description/(x:output, x:scenario/x:call/x:input)[@port=&quot;',$port,'&quot;]/x:document')"/>
            </p:filter>
            <p:count/>
            <pxi:assert>
                <p:with-option name="test" select="number(/*) &gt; 0"/>
                <p:with-option name="message" select="concat('   * port not found: &quot;',$port,'&quot;')"/>
                <p:with-option name="logfile" select="$logfile">
                    <p:empty/>
                </p:with-option>
            </pxi:assert>
            
            <p:identity>
                <p:input port="source">
                    <p:pipe port="result" step="port"/>
                </p:input>
            </p:identity>
            <p:choose>
                <p:xpath-context>
                    <p:inline>
                        <doc/>
                    </p:inline>
                </p:xpath-context>
                <p:when test="$position='all'">
                    <p:identity/>
                </p:when>
                <p:otherwise>
                    <p:split-sequence initial-only="true">
                        <p:with-option name="test" select="concat('position()=',(if ($position='last') then 'last()' else $position))"/>
                    </p:split-sequence>
                </p:otherwise>
            </p:choose>
            <p:for-each>
                <p:variable name="base" select="resolve-uri((/*/@xml:base,/*/base-uri())[1],$base-dir)"/>
                <p:delete match="/*/@*"/>
                <p:add-attribute match="/*" attribute-name="xml:base">
                    <p:with-option name="attribute-value" select="if (/*/*/@xml:base) then resolve-uri(/*/*/@xml:base,$base) else $base"/>
                </p:add-attribute>
            </p:for-each>
        </p:when>

        <p:when test="$type='file'">
            <p:identity>
                <p:input port="source">
                    <p:pipe port="document" step="main"/>
                </p:input>
            </p:identity>
            <p:group>
                <p:variable name="base" select="resolve-uri((/*/@xml:base,/*/base-uri())[1],$base-dir)"/>
                <pxi:load>
                    <p:with-option name="href" select="$href"/>
                    <p:with-option name="method" select="$method"/>
                    <p:with-option name="logfile" select="$logfile"/>
                </pxi:load>
                <p:wrap-sequence wrapper="x:document"/>
                <p:add-attribute match="/*" attribute-name="xml:base">
                    <p:with-option name="attribute-value" select="if (/*/*/@xml:base) then resolve-uri(/*/*/@xml:base,$base) else $base"/>
                </p:add-attribute>
            </p:group>
        </p:when>

        <p:when test="$type='directory'">
            <pxi:directory-list>
                <p:with-option name="path" select="$href"/>
                <p:with-option name="depth" select="if ($recursive='true') then '-1' else '0'"/>
            </pxi:directory-list>
            <p:delete match="//*/@xml:base"/>
            <p:wrap-sequence wrapper="x:document"/>
            <p:add-attribute match="/*" attribute-name="xml:base">
                <p:with-option name="attribute-value" select="$href"/>
            </p:add-attribute>
        </p:when>

        <p:when test="$type='errors'">
            <p:for-each>
                <p:iteration-source select="(/x:description/c:errors)[1]"/>
                <p:identity/>
            </p:for-each>
            <p:identity name="errors"/>
            <p:count name="errors.count"/>
            <p:choose>
                <p:when test=".='0'">
                    <p:identity>
                        <p:input port="source">
                            <p:pipe port="result" step="errors"/>
                        </p:input>
                    </p:identity>
                    <pxi:message message="    * no errors occured">
                        <p:with-option name="logfile" select="$logfile">
                            <p:empty/>
                        </p:with-option>
                    </pxi:message>
                </p:when>
                <p:otherwise>
                    <p:identity>
                        <p:input port="source">
                            <p:pipe port="result" step="errors"/>
                        </p:input>
                    </p:identity>
                    
                    <p:group>
                        <p:variable name="base" select="base-uri(/*)"/>
                        <p:wrap-sequence wrapper="x:document"/>
                        <pxi:assert message="   * error document contains no errors">
                            <p:with-option name="test" select="count(/*/*) &gt; 0"/>
                            <p:with-option name="logfile" select="$logfile">
                                <p:empty/>
                            </p:with-option>
                        </pxi:assert>
                        <p:add-attribute match="/*" attribute-name="xml:base">
                            <p:with-option name="attribute-value" select="if (/*/*/@xml:base) then resolve-uri(/*/*/@xml:base,$base) else $base"/>
                        </p:add-attribute>
                    </p:group>
                </p:otherwise>
            </p:choose>
        </p:when>
        
        <p:otherwise>
            <!-- default is 'inline' -->
            <p:identity>
                <p:input port="source">
                    <p:pipe port="document" step="main"/>
                </p:input>
            </p:identity>
            <p:group>
                <p:variable name="base" select="resolve-uri((/*/@xml:base,/*/base-uri())[1],$base-dir)"/>
                <p:delete match="@*"/>
                <p:add-attribute match="/*" attribute-name="xml:base">
                    <p:with-option name="attribute-value" select="if (/*/*/@xml:base) then resolve-uri(/*/*/@xml:base,$base) else $base"/>
                </p:add-attribute>
            </p:group>
        </p:otherwise>
    </p:choose>
    
    <p:for-each>
        <p:add-attribute match="/*" attribute-name="type" attribute-value="inline"/>
    </p:for-each>

</p:declare-step>
