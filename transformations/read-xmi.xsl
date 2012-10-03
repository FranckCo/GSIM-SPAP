<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:uml="http://schema.omg.org/spec/UML/2.1" xmlns:xmi="http://schema.omg.org/spec/XMI/2.1" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:gsim="http://unece.org/gsim/0.8" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xs" version="2.0">

    <xsl:output method="xml" indent="yes"/>

    <!-- Main template -->
    <xsl:template match="/">
        <gsim:Model>
            <!-- Call template on top level packages -->
            <xsl:apply-templates select="/xmi:XMI/uml:Model/packagedElement/packagedElement"/>
            <!-- Call template on diagrams -->
            <gsim:Diagrams>
                <xsl:apply-templates select="/xmi:XMI/xmi:Extension/diagrams/diagram"/>
            </gsim:Diagrams>
        </gsim:Model>
    </xsl:template>

    <!-- Template for top level packages -->
    <xsl:template match="packagedElement[@xmi:type='uml:Package']">
        <xsl:variable name="package-id" select="@xmi:id"/>
        <gsim:Package>
            <xsl:attribute name="id" select="$package-id"/>
            <gsim:Name>
                <xsl:value-of select="@name"/>
            </gsim:Name>
            <!-- Call templates for classes -->
            <gsim:Classes>
                <xsl:apply-templates select="packagedElement[@xmi:type='uml:Class']"/>
            </gsim:Classes>
            <!-- Call templates for associations -->
            <gsim:Associations>
                <xsl:apply-templates select="packagedElement[@xmi:type='uml:Association']"/>
            </gsim:Associations>
            <!-- Add enumerations, notes, constraints -->
        </gsim:Package>
    </xsl:template>

    <!-- Template for UML classes -->
    <xsl:template match="packagedElement[@xmi:type='uml:Class']">
        <xsl:variable name="class-name" select="@name"/>
        <xsl:variable name="class-id" select="@xmi:id"/>
        <xsl:variable name="class-ext" select="/xmi:XMI/xmi:Extension/elements/element[@xmi:idref=$class-id]"/>

        <gsim:Class id="{$class-id}">
            <xsl:if test="@isAbstract=true()">
                <xsl:attribute name="abstract" select="true()"/>
            </xsl:if>
            <gsim:Name>
                <xsl:value-of select="$class-name"/>
            </gsim:Name>
            <xsl:if test="$class-ext[1]/properties/@documentation">
                <gsim:Doc>
                    <xsl:value-of select="$class-ext[1]/properties/@documentation" disable-output-escaping="yes"/>
                </gsim:Doc>
            </xsl:if>
 
            <!-- List the attributes of this class -->
            <xsl:for-each select="ownedAttribute">
                <xsl:variable name="att-id" select="@xmi:id"/>
                <xsl:if test="(string-length($att-id)> 0) and not(@association)">
                    <!-- The id test is probably useless, but some 'attributes' are in fact association endpoints -->
                    <!-- Retrieve the EA extension for the attribute (there should be one and only one) in order to get the type and documentation -->
                    <xsl:variable name="att-ext" select="/xmi:XMI/xmi:Extension/elements/element/attributes/attribute[@xmi:idref=$att-id]"/>
                    <gsim:Attribute id="{$att-id}">
                        <gsim:Name>
                            <xsl:value-of select="@name"/>
                        </gsim:Name>
                        <xsl:if test="$att-ext[1]/documentation/@value">
                            <gsim:AttDoc>
                                <xsl:value-of select="$att-ext[1]/documentation/@value" disable-output-escaping="yes"/>
                            </gsim:AttDoc>
                        </xsl:if>
                        <gsim:AttType>
                            <xsl:value-of select="$att-ext[1]/properties/@type"/>
                        </gsim:AttType>
                        <gsim:Min>
                            <xsl:value-of select="lowerValue/@value"/>
                        </gsim:Min>
                        <gsim:Max>
                            <xsl:value-of select="upperValue/@value"/>
                        </gsim:Max>
                    </gsim:Attribute>
                </xsl:if>
            </xsl:for-each>

            <!-- List the relations involving this class (this seems to be easier to do starting from the extension part of the model) -->
            <!-- Generalizations and specializations -->
            <xsl:for-each select="$class-ext[1]/links/Generalization/self::node()[@start=$class-id]">
                <xsl:variable name="end-id" select="@end"/>
                <xsl:variable name="other-end" select="/xmi:XMI/uml:Model//packagedElement[@xmi:id=$end-id]"/>
                <gsim:Specializes class="{$other-end/@name}"/>
            </xsl:for-each>
            <xsl:for-each select="$class-ext[1]/links/Generalization/self::node()[@end=$class-id]">
                <xsl:variable name="end-id" select="@start"/>
                <xsl:variable name="other-end" select="/xmi:XMI/uml:Model//packagedElement[@xmi:id=$end-id]"/>
                <gsim:Generalizes class="{$other-end/@name}"/>
            </xsl:for-each>

            <!-- Aggregations (including compositions) starting from the current class -->
            <xsl:for-each select="$class-ext[1]/links/Aggregation/self::node()[@start=$class-id]">
                <gsim:Aggregation>
                    <!-- Register the associations's id -->
                    <xsl:attribute name="id" select="@xmi:id"/>
                    <xsl:attribute name="role">start</xsl:attribute>
                    <!-- Retrieve the name of the end class in the UML part of the document -->
                    <xsl:variable name="end-class-id" select="@end"/>
                    <gsim:EndClass><xsl:value-of select="/xmi:XMI/uml:Model//packagedElement[@xmi:id=$end-class-id]/@name"/></gsim:EndClass>
                </gsim:Aggregation>
            </xsl:for-each>
            <!-- Aggregations (including compositions) ending at the current class -->
            <xsl:for-each select="$class-ext[1]/links/Aggregation/self::node()[@end=$class-id]">
                <gsim:Aggregation>
                    <!-- Register the associations's id -->
                    <xsl:attribute name="id" select="@xmi:id"/>
                    <xsl:attribute name="role">end</xsl:attribute>
                    <!-- Retrieve the name of the end class in the UML part of the document -->
                    <xsl:variable name="start-class-id" select="@start"/>
                    <gsim:StartClass><xsl:value-of select="/xmi:XMI/uml:Model//packagedElement[@xmi:id=$start-class-id]/@name"/></gsim:StartClass>
                </gsim:Aggregation>
            </xsl:for-each>

            <!-- Other associations starting from the current class -->
            <xsl:for-each select="$class-ext[1]/links/Association/self::node()[@start=$class-id]">
                <gsim:Association>
                    <!-- Register the associations's id -->
                    <xsl:attribute name="id" select="@xmi:id"/>
                    <xsl:attribute name="role">start</xsl:attribute>
                    <!-- Retrieve the name of the end class in the UML part of the document -->
                    <xsl:variable name="end-class-id" select="@end"/>
                    <gsim:EndClass><xsl:value-of select="/xmi:XMI/uml:Model//packagedElement[@xmi:id=$end-class-id]/@name"/></gsim:EndClass>
                </gsim:Association>
            </xsl:for-each>
            <!-- Other associations ending at the current class -->
            <xsl:for-each select="$class-ext[1]/links/Association/self::node()[@end=$class-id]">
                <gsim:Association>
                    <!-- Register the associations's id -->
                    <xsl:attribute name="id" select="@xmi:id"/>
                    <xsl:attribute name="role">end</xsl:attribute>
                    <!-- Retrieve the name of the end class in the UML part of the document -->
                    <xsl:variable name="start-class-id" select="@start"/>
                    <gsim:StartClass><xsl:value-of select="/xmi:XMI/uml:Model//packagedElement[@xmi:id=$start-class-id]/@name"/></gsim:StartClass>
                </gsim:Association>
            </xsl:for-each> 
        </gsim:Class>
    </xsl:template>

    <!-- Template for UML associations -->
    <xsl:template match="packagedElement[@xmi:type='uml:Association']">
        <gsim:Association id="{@xmi:id}">
            <xsl:if test="@name">
                <gsim:Name><xsl:value-of select="@name"/></gsim:Name>
            </xsl:if>
            <!-- All associations have exactly 2 elements memberEnd and 1 or 2 elements ownedEnd -->
            <xsl:for-each select="ownedEnd">
                <xsl:choose>
                    <xsl:when test="starts-with(@xmi:id, 'EAID_src')">
                        <xsl:element name="gsim:Source">
                            <xsl:call-template name="process-endpoint">
                                <xsl:with-param name="end-element" select="."/>
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="gsim:Destination">
                            <xsl:call-template name="process-endpoint">
                                <xsl:with-param name="end-element" select="."/>
                            </xsl:call-template>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            
            <xsl:if test="count(ownedEnd)=1">
                <!-- When there is only one ownedEnd, it is always the source, and the destination points to an attribute in the linked class -->
                <xsl:variable name="owned-end-id" select="ownedEnd/@xmi:id"/>
                <xsl:variable name="not-owned-end-id" select="memberEnd[not(@xmi:idref=$owned-end-id)]/@xmi:idref"/>
                <gsim:Destination>
                    <xsl:call-template name="process-endpoint">
                        <xsl:with-param name="end-element" select="/xmi:XMI/uml:Model//packagedElement/ownedAttribute[@xmi:id=$not-owned-end-id]"/>
                    </xsl:call-template>
                </gsim:Destination>
            </xsl:if>
        </gsim:Association>
    </xsl:template>

    <xsl:template match="diagram">
        <gsim:Diagram>
            <gsim:Name>
                <xsl:value-of select="properties/@name"/>
            </gsim:Name>
            <gsim:DiagramDoc>
                <xsl:value-of select="properties/@documentation" disable-output-escaping="yes"/>
            </gsim:DiagramDoc>
        </gsim:Diagram>
    </xsl:template>


    <xsl:template name="process-endpoint">
        <xsl:param name="end-element"/>
        <xsl:if test="$end-element/@name">
            <gsim:Name><xsl:value-of select="$end-element/@name"/></gsim:Name>
        </xsl:if>
        <xsl:variable name="class-id" select="$end-element/type/@xmi:idref"/>
        <gsim:LinkedClass><xsl:value-of select="/xmi:XMI/uml:Model//packagedElement[@xmi:id=$class-id]/@name"></xsl:value-of></gsim:LinkedClass>
        <xsl:for-each select="$end-element/lowerValue">
            <gsim:Min>
                <xsl:value-of select="@value"/>
            </gsim:Min>
        </xsl:for-each>
        <xsl:for-each select="$end-element/upperValue">
            <xsl:choose>
                <xsl:when test="@xmi:type='uml:LiteralUnlimitedNatural'">
                    <gsim:Max>n</gsim:Max>
                </xsl:when>
                <xsl:otherwise>
                    <gsim:Max>
                        <xsl:value-of select="@value"/>
                    </gsim:Max>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:if test="$end-element/@aggregation='composite'">
            <gsim:Composition/>
        </xsl:if>
    </xsl:template>

    <!-- Avoid default copy -->
    <xsl:template match="@*|node()"/>

</xsl:stylesheet>