#' Calculate isotopic ages
#'
#' Calculates U-Pb ages and propagates their analytical
#' uncertainties. Evaluates the equivalence of multiple
#' (\eqn{^{206}}Pb/\eqn{^{238}}U-\eqn{^{207}}Pb/\eqn{^{235}}U or
#' \eqn{^{207}}Pb/\eqn{^{206}}Pb-\eqn{^{206}}Pb/\eqn{^{238}}U)
#' compositions, computes the weighted mean isotopic composition and
#' the corresponding concordia age using the method of maximum
#' likelihood, computes the mswd of equivalence and concordance and
#' their respective Chi-squared p-values. Performs linear regression
#' of U-Pb data on Wetherill and Tera-Wasserburg concordia
#' diagrams. Computes the upper and lower intercept ages (for
#' Wetherill) or the lower intercept age and the
#' \eqn{^{207}}Pb/\eqn{^{206}}Pb intercept (for Tera-Wasserburg),
#' taking into account error correlations and decay constant
#' uncertainties.
#'
#' @param x can be:
#'
#' a scalar containing an isotopic ratio,
#'
#' a two element vector containing an isotopic ratio and its standard error,
#'
#' a four element vector containing \code{Ar40Ar39},
#' \code{s[Ar40Ar39]}, \code{J}, \code{s[J]},
#'
#' an six element vector containing \code{U}, \code{s[U]}, \code{Th},
#' \code{s[Th]}, \code{He} and \code{s[He]}
#'
#' an eight element vector containing \code{U}, \code{s[U]}, \code{Th},
#' \code{s[Th]}, \code{He}, \code{s[He]}, \code{Sm} and \code{s[Sm]},
#'
#' OR
#' 
#' an object of class \code{UPb}, \code{ArAr} or \code{UThHe}.
#' 
#' @param method one of either \code{'Pb206U238'}, \code{'Pb207U235'},
#'     \code{'Pb207Pb206'}, \code{'Ar40Ar39'} or \code{U-Th-He}
#' 
#' @param dcu propagate the decay constant uncertainties?
#' 
#' @param J two element vector with the J-factor and its standard
#'     error.  This option is only used if \code{method} =
#'     \code{'Ar40Ar39'}.
#' 
#' @param i (optional) index of a particular aliquot
#' 
#' @param ... optional arguments
#' 
#' @return if \code{x} is a scalar or a vector, returns the age using
#'     the geochronometer given by \code{method} and its standard
#'     error.
#' @rdname age
#' @export
age <- function(x,...){ UseMethod("age",x) }
#' @rdname age
#' @export
age.default <- function(x,method='Pb206U238',dcu=TRUE,J=c(NA,NA),...){
    if (length(x)==1) X <- c(x,0)
    else X <- x[1:2]
    if (identical(method,'Pb207U235'))
        out <- get.Pb207U235age(X[1],X[2],dcu)
    else if (identical(method,'Pb206U238'))
        out <- get.Pb206U238age(X[1],X[2],dcu)
    else if (identical(method,'Pb207Pb206'))
        out <- get.Pb207Pb206age(X[1],X[2],dcu)
    else if (identical(method,'Ar40Ar39'))
        out <- get.ArAr.age(X[1],X[2],X[3],X[4],dcu)
    else if (identical(method,'U-Th-He'))
        if (length(x)==6)
            out <- get.UThHe.age(X[1],X[2],X[3],X[4],X[5],X[6])
        else if (length(x)==8)
            out <- get.UThHe.age(X[1],X[2],X[3],X[4],X[5],X[6],X[7],X[8])
    out
}
#' @param concordia scalar flag indicating whether each U-Pb analysis
#'     should be considered separately (\code{concordia=1}), a
#'     concordia age should be calculated from all U-Pb analyses
#'     together (\code{concordia=2}), or a discordia line should be
#'     fit through all the U-Pb analyses (\code{concordia=2}).
#' 
#' @param wetherill boolean flag to indicate whether the data should
#'     be evaluated in Wetherill (\code{TRUE}) or Tera-Wasserburg
#'     (\code{FALSE}) space.  This option is only used when
#'     \code{concordia=2}
#' 
#' @param sigdig number of significant digits for the uncertainty
#'     estimate (only used if \code{concordia=1},
#'     \code{isochron=FALSE} or \code{central=FALSE}).
#' 
#' @return
#' if \code{x} has class \code{UPb} and \code{concordia=1}, returns a
#' table with the following columns: `t.75', `err[t.75]', `t.68',
#' `err[t.68]', `t.76',`err[t.76]', `t.conc', `err[t.conc]',
#' containing the 207Pb/235U-age and standard error, the
#' \eqn{^{206}}Pb/\eqn{^{238}}U-age and standard error, the
#' \eqn{^{207}}Pb/\eqn{^{206}} Pb-age and standard error, and the
#' concordia age and standard error, respectively.
#'  
#' if \code{x} has class \code{UPb} and \code{concordia=2}, returns a
#' list with the following items:
#'
#' \describe{
#' \item{x}{ a named vector with the (weighted mean) U-Pb composition }
#' 
#' \item{cov}{ the covariance matrix of the (mean) U-Pb composition }
#' 
#' \item{age}{ the concordia age (in Ma) }
#' 
#' \item{age.err}{ the standard error of the concordia age }
#' 
#' \item{mswd}{ a list with two items (\code{equivalence} and
#' \code{concordance}) containing the MSWD (Mean of the Squared
#' Weighted Deviates, a.k.a the reduced Chi-squared statistic outside
#' of geochronology) of isotopic equivalence and age concordance,
#' respectively. }
#' 
#' \item{p.value}{ a list with two items (\code{equivalence} and
#' \code{concordance}) containing the p-value of the Chi-square test
#' for isotopic equivalence and age concordance, respectively. }
#' }
#' 
#' if \code{x} has class \code{UPb} and \code{concordia=3}, returns a
#' list with the following items:
#'
#' \describe{
#' \item{x}{ a two element vector with the upper and lower intercept
#' ages (if wetherill==TRUE) or the lower intercept age and
#' \eqn{^{207}}Pb/\eqn{^{206}}Pb intercept (for Tera-Wasserburg) }
#' 
#' \item{cov}{ the covariance matrix of the elements in \code{x} }
#' }
#'
#' if \code{x} has class \code{ArAr} and \code{isochron=FALSE},
#' returns a table of Ar-Ar ages and standard errors.
#'
#' if \code{x} has class \code{ArAr} and \code{isochron=TRUE},
#' returns a list with the following items:
#'
#' \describe{
#'
#' \item{a}{ the intercept of the straight line fit and its standard
#' error. }
#' 
#' \item{b}{ the slope of the fit and its standard error. }
#' 
#' \item{y0}{ the atmospheric \eqn{^{40}}Ar/\eqn{^{36}}Ar ratio and
#' its standard error. }
#' 
#' \item{age}{ the \eqn{^{40}}Ar/\eqn{^{39}}Ar age and its standard
#' error. }
#' 
#' }
#' 
#' if \code{x} has class \code{UThHe} and \code{central=FALSE},
#' returns a table of U-Th-He ages and standard errors.
#' 
#' if \code{x} has class \code{UThHe} and \code{central=TRUE},
#' returns a list with the following items:
#'
#' \describe{
#'
#' \item{uvw}{ a three-element list with the weighted mean log[U/He],
#' log[Th/He] and log[Sm/He] compositions. }
#'
#' \item{covmat}{ a 3x3 covariance matrix for uvw}
#'
#' \item{mswd}{ the reduced Chi-square value for the
#' log[U/He]-log[Th/He] compositions. }
#'
#' \item{p.value}{ the p-value of concordance between the
#' log[U/He]-log[Th/He] compositions. }
#'
#' \item{age}{ two-element vector with the central age and its
#' standard error. }
#' 
#' }
#' 
#' @examples
#' data(examples)
#' print(age(examples$UPb))
#' print(age(examples$UPb,concordia=1))
#' print(age(examples$UPb,concordia=2))
#' @rdname age
#' @export
age.UPb <- function(x,concordia=1,wetherill=TRUE,
                    dcu=TRUE,i=NA,sigdig=2,...){
    if (concordia==1)
        out <- UPb.age(x,dcu=dcu,i=i,sigdig=sigdig,...)
    else if (concordia==2)
        out <- concordia.age(x,wetherill=TRUE,dcu=TRUE,...)
    else if (concordia==3)
        out <- discordia.age(x,wetherill=TRUE,dcu=TRUE,...)
    out
}
#' @rdname age
#' @export
age.detritals <- function(x,...){
    x
}
#' @param isochron Boolean flag indicating whether each Ar-Ar analysis
#'     should be considered separately (\code{isochron=FALSE}) or an
#'     isochron age should be calculated from all Ar-Ar analyses
#'     together (\code{isochron=TRUE}).
#' @rdname age
#' @export
age.ArAr <- function(x,isochron=FALSE,dcu=TRUE,i=NA,sigdig=2,...){
    if (isochron) out <- isochron(x,plot=FALSE)
    else out <- ArAr.age(x,dcu=dcu,i=i,sigdig=sigdig,...)
    out
}
#' @param central Boolean flag indicating whether each U-Th-He analysis
#'     should be considered separately (\code{central=FALSE}) or a
#'     central age should be calculated from all U-Th-He analyses
#'     together (\code{central=TRUE}).
#' @rdname age
#' @export
age.UThHe <- function(x,central=FALSE,i=NA,sigdig=2,...){
    if (central) out <- centralage(x)
    else out <- UThHe.age(x,i=i,sigdig=sigdig)
    out
}