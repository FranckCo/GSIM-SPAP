<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:uml="http://schema.omg.org/spec/UML/2.1" xmlns:xmi="http://schema.omg.org/spec/XMI/2.1" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:gsim="http://unece.org/gsim/0.8" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xs" version="2.0">

    <xsl:output method="xml" indent="yes"/>

    <!-- Main template -->
    <xsl:template match="/">
        <gsim:Model>
            <!-- Call template on top level packages -->
            <xsl:apply-templates select="/xmi:XMI/uml:Model/packagedElement"/>
            <!-- Call template on diagrams -->
            <xsl:apply-templates select="/xmi:XMI/xmi:Extension/diagrams/diagram"/>
        </gsim:Model>
    </xsl:template>

    <!-- Template for top level packages -->
    <xsl:template match="packagedElement[@xmi:type='uml:Package']">
        <gsim:Package>
            <xsl:attribute name="id" select="@xmi:id"/>
            <gsim:Name>
                <xsl:value-of select="@name"/>
            </gsim:Name>
            <gsim:Classes>
                <!-- Call templates for classes -->
                <xsl:apply-templates select="packagedElement[@xmi:type='uml:Class']"/>
            </gsim:Classes>
            <!-- Add enumerations, notes, constraints -->
        </gsim:Package>
    </xsl:template>

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
                <xsl:if test="(string-length($att-id)> 0) and @name">
                    <!-- The id test is probably useless, but some attributes don't have names -->
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

            <!-- List the relations *starting* from the class : specializations, generalizations, aggregations, associations -->
            <xsl:for-each select="$class-ext[1]/links/Generalization/self::node()[@start=$class-id]">
                <xsl:variable name="end-id" select="@end"/>
                <xsl:variable name="other-end" select="/xmi:XMI/uml:Model/packagedElement/packagedElement[@xmi:id=$end-id]"/>
                <gsim:Specializes class="{$other-end/@name}"/>
            </xsl:for-each>
            <xsl:for-each select="$class-ext[1]/links/Generalization/self::node()[@end=$class-id]">
                <xsl:variable name="end-id" select="@start"/>
                <xsl:variable name="other-end" select="/xmi:XMI/uml:Model/packagedElement/packagedElement[@xmi:id=$end-id]"/>
                <gsim:Generalizes class="{$other-end/@name}"/>
            </xsl:for-each>
            <xsl:for-each select="$class-ext[1]/links/Aggregation/self::node()[@start=$class-id]">
                <gsim:Aggregation>
                    <!-- Retrieve the link's id attribute -->
                    <xsl:variable name="link-id" select="@xmi:id"/>
                    <!-- Now retrieve the association in the UML part of the file (there should be one and only one) -->
                    <xsl:variable name="association-node" select="/xmi:XMI/uml:Model/packagedElement/packagedElement[@xmi:id=$link-id]"/>
                    <!-- Read the name of the aggregation if it has one -->
                    <xsl:variable name="association-name" select="$association-node[1]/@name"/>
                    <xsl:if test="string-length($association-name) > 0">
                        <xsl:attribute name="name">
                            <xsl:value-of select="$association-name"/>
                        </xsl:attribute>
                    </xsl:if>
                    <!-- In case of aggregations, we only have one ownedEnd element -->
                    <xsl:for-each select="$association-node[1]/ownedEnd">
                        <xsl:variable name="end-name" select="@name"/>
                        <xsl:variable name="end-class-id" select="type/@xmi:idref"/>
                        <xsl:variable name="other-class-node" select="/xmi:XMI/uml:Model/packagedElement/packagedElement[@xmi:id=$end-class-id]"/>
                        <xsl:if test="@aggregation='composite'">
                            <gsim:Composition/>
                        </xsl:if>
                        <gsim:OtherEnd>
                            <gsim:ClassName>
                                <xsl:value-of select="$other-class-node/@name"/>
                            </gsim:ClassName>
                            <xsl:if test="string-length($end-name) > 0">
                                <gsim:Name>
                                    <xsl:value-of select="$end-name"/>
                                </gsim:Name>
                            </xsl:if>
                        </gsim:OtherEnd>
                    </xsl:for-each>
                </gsim:Aggregation>
            </xsl:for-each>
            <xsl:for-each select="$class-ext[1]/links/Association/self::node()[@start=$class-id]">
                <gsim:Association>
                    <!-- Retrieve the link's id attribute -->
                    <xsl:variable name="link-id" select="@xmi:id"/>
                    <!-- Now retrieve the association in the UML part of the file (there should be one and only one) -->
                    <xsl:variable name="association-node" select="/xmi:XMI/uml:Model/packagedElement/packagedElement[@xmi:id=$link-id]"/>
                    <!-- Read the name of the association if it has one -->
                    <xsl:variable name="association-name" select="$association-node[1]/@name"/>
                    <xsl:if test="string-length($association-name) > 0">
                        <xsl:attribute name="name">
                            <xsl:value-of select="$association-name"/>
                        </xsl:attribute>
                    </xsl:if>
                    <!-- In case of associations, we have two ownedEnd elements -->
                    <xsl:for-each select="$association-node[1]/ownedEnd">
                        <xsl:variable name="end-name" select="@name"/>
                        <xsl:variable name="end-class-id" select="type/@xmi:idref"/>
                        <xsl:choose>
                            <xsl:when test="$end-class-id=$class-id">
                                <gsim:ThisEnd>
                                    <xsl:if test="string-length($end-name) > 0">
                                        <gsim:Name>
                                            <xsl:value-of select="$end-name"/>
                                        </gsim:Name>
                                    </xsl:if>
                                    <xsl:call-template name="get-cardinalities">
                                        <xsl:with-param name="end-element" select="."/>
                                    </xsl:call-template>
                                </gsim:ThisEnd>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="other-class-node"
                                    select="/xmi:XMI/uml:Model/packagedElement/packagedElement[@xmi:id=$end-class-id]"/>
                                <gsim:OtherEnd>
                                    <gsim:ClassName>
                                        <xsl:value-of select="$other-class-node/@name"/>
                                    </gsim:ClassName>
                                    <xsl:if test="string-length($end-name) > 0">
                                        <gsim:Name>
                                            <xsl:value-of select="$end-name"/>
                                        </gsim:Name>
                                    </xsl:if>
                                </gsim:OtherEnd>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </gsim:Association>

            </xsl:for-each>
        </gsim:Class>
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

    <xsl:template name="get-cardinalities">
        <xsl:param name="end-element"/>
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
    </xsl:template>

    <!-- Not used -->
    <xsl:template name="process-relation">
        <xsl:param name="link-node"/>
        <!-- Retrieve the link's id attribute -->
        <xsl:variable name="link-id" select="$link-node/@xmi:id"/>
        <!-- Now retrieve the association in the UML part of the file (there should be one and only one) -->
        <xsl:variable name="association-node" select="/xmi:XMI/uml:Model/packagedElement/packagedElement[@xmi:id=$link-id]"/>
        <!-- Now retrieve the connector in the EA part of the file (there should be one and only one) -->
        <xsl:variable name="connector-node" select="/xmi:XMI/xmi:Extension/connectors/connector[@xmi:idref=$link-id]"/>

        <xsl:for-each select="$association-node[1]/memberEnd">
            <gsim:Member/>
        </xsl:for-each>
        <xsl:for-each select="$association-node[1]/ownedEnd">
            <gsim:Owner/>
        </xsl:for-each>

    </xsl:template>

    <xsl:template match="@*|node()"/>

</xsl:stylesheet>