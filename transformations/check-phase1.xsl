<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:uml="http://schema.omg.org/spec/UML/2.1" xmlns:xmi="http://schema.omg.org/spec/XMI/2.1" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:gsim="http://unece.org/gsim/0.8" xmlns="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xs" version="2.0">

    <xsl:output method="xml" indent="yes"/>

    <!-- Main template -->
    <xsl:template match="/">
        <gsim:Checks>
            <xsl:apply-templates select="gsim:Model"/>
        </gsim:Checks>
    </xsl:template>

    <xsl:template match="gsim:Model">
        <!-- Checking if all aggregations referenced in classes are present in the document -->
        <xsl:for-each select="gsim:Package/gsim:Classes/gsim:Class/gsim:Aggregation">
            <xsl:variable name="id" select="@id"/>
            <xsl:if test="count(//gsim:Associations/gsim:Association[@id=$id])=0">
                <gsim:Error>Missing description for aggregation <xsl:value-of select="$id"/></gsim:Error>
            </xsl:if>
        </xsl:for-each>
        <!-- Same thing for generic associations -->
        <xsl:for-each select="gsim:Package/gsim:Classes/gsim:Class/gsim:Association">
            <xsl:variable name="id" select="@id"/>
            <xsl:if test="count(//gsim:Associations/gsim:Association[@id=$id])=0">
                <gsim:Error>Missing description for association <xsl:value-of select="$id"/></gsim:Error>
            </xsl:if>
        </xsl:for-each>
        <!-- Checking if the start of an aggregation in the Class element is always the source of the corresponding Association element -->
        <xsl:for-each select="gsim:Package/gsim:Classes/gsim:Class/gsim:Aggregation[@role='start']">
            <xsl:variable name="id" select="@id"/>
            <xsl:variable name="class-name" select="../gsim:Name"/>
            <xsl:variable name="source-class-name" select="//gsim:Associations/gsim:Association[@id=$id]/gsim:Source/gsim:LinkedClass"/>
            <xsl:if test="not($source-class-name=$class-name)">
                <gsim:Error>Source/start mismatch for aggregation <xsl:value-of select="$id"/> - start = <xsl:value-of select="$class-name"/> - source = <xsl:value-of select="$source-class-name"/></gsim:Error>
            </xsl:if>
        </xsl:for-each>
        <!-- Checking if the start of an association in the Class element is always the source of the corresponding Association element -->
        <xsl:for-each select="gsim:Package/gsim:Classes/gsim:Class/gsim:Association[@role='start']">
            <xsl:variable name="id" select="@id"/>
            <xsl:variable name="class-name" select="../gsim:Name"/>
            <xsl:variable name="source-class-name" select="//gsim:Associations/gsim:Association[@id=$id]/gsim:Source/gsim:LinkedClass"/>
            <xsl:if test="not($source-class-name=$class-name)">
                <gsim:Error>Source/start mismatch for association <xsl:value-of select="$id"/> - start = <xsl:value-of select="$class-name"/> - source = <xsl:value-of select="$source-class-name"/></gsim:Error>
            </xsl:if>
        </xsl:for-each>
        <!-- Same checks with end and Destination -->
        <xsl:for-each select="gsim:Package/gsim:Classes/gsim:Class/gsim:Aggregation[@role='end']">
            <xsl:variable name="id" select="@id"/>
            <xsl:variable name="class-name" select="../gsim:Name"/>
            <xsl:variable name="dest-class-name" select="//gsim:Associations/gsim:Association[@id=$id]/gsim:Destination/gsim:LinkedClass"/>
            <xsl:if test="not($dest-class-name=$class-name)">
                <gsim:Error>Destination/end mismatch for aggregation <xsl:value-of select="$id"/> - end = <xsl:value-of select="$class-name"/> - destination = <xsl:value-of select="$dest-class-name"/></gsim:Error>
            </xsl:if>
        </xsl:for-each>
        <xsl:for-each select="gsim:Package/gsim:Classes/gsim:Class/gsim:Association[@role='end']">
            <xsl:variable name="id" select="@id"/>
            <xsl:variable name="class-name" select="../gsim:Name"/>
            <xsl:variable name="dest-class-name" select="//gsim:Associations/gsim:Association[@id=$id]/gsim:Destination/gsim:LinkedClass"/>
            <xsl:if test="not($dest-class-name=$class-name)">
                <gsim:Error>Destination/end mismatch for association <xsl:value-of select="$id"/> - end = <xsl:value-of select="$class-name"/> - destination = <xsl:value-of select="$dest-class-name"/></gsim:Error>
            </xsl:if>
        </xsl:for-each>

    </xsl:template>

</xsl:stylesheet>