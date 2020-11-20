classdef Laf < CfgBase
    properties(Access=private,Constant)
        uname = 'Laf';    
    end
    
    properties
        % default = 0.5 delky hran rovnoramenneho trojuhelniku vepisovaneho do
        % polygonu, uhel pak urcuje krivost
        curvatureArcLength = 0.5;

        % default = 1.0 vzdalenost (po hrani polygonu) pro non-maxima-suppression
        % pri hledani maxim krivosti
        curvatureNMSSpan = 1;

        % default = true
        doContourSmoothing = 1;
        doRegressionPositioning = 0;
        doInflectionPrecising = 0;
        doLocalExtremaPrecising = 0;

        % default = 0 - sigma derived from the size of the region by default,
        % non-zero value fixed smoothing sigma
        fixedContourSmoothingSigma = 0;

        contourLinearApproximationDistanceThreshold = 0.033;

        % default = true
        ignoreQueryBlackPixels = 0;


        lafExtremalCurvatureTreshold = 0.15; % cca 135
                                                      % stupnov

        % default = 5, minimalni pocet pixelu v ramci, tj. determinant
        % transformacni matice obrazek -> normalizovany ramec
        lafMinimalFrameSize = 5;
        lafTangentPointCurvatureTreshold = 0.1;
        lafFarthestPointCurvatureTreshold = 0.15;
        lafDoWeightRaster = 1;
        lafRasterWeightsSigma = 2;
        lafMaxNOfCurvatureExtremaPerDR = 5;
        lafMinIntensityVariance = 10;
        lafMinimalLinearSegmentLength = 2;


        % LAF_CG_CURV_MIN      ///< 1: cov. matrix (CM) of DR + center of gravity (CoG) of DR + point of maximal concave curvature
        lafConstructsToUse_LAF__LAF_CG_CURV_MIN = 1;

        % LAF_CG_CURV_MAX,     ///< 2: CM of DR + CoG of DR + point of maximal convex curvature
        lafConstructsToUse_LAF__LAF_CG_CURV_MAX = 1;

        % LAF_2TP_CG,          ///< 3: 2 tangent points on a concavity + CoG of DR
        lafConstructsToUse_LAF__LAF_2TP_CG = 0;

        % LAF_2TP_CONT,        ///< 4: 2 tangent points on a concavity + point of DR contour most distant from the bitangent line
        lafConstructsToUse_LAF__LAF_2TP_CONT = 0;

        % LAF_2TP_CONC,        ///< 5: 2 tangent points on a concavity + point of the concavity most distant from the bitangent line
        lafConstructsToUse_LAF__LAF_2TP_CONC = 1;

        % LAF_2TP_CCG,         ///< 6: 2 tangent points on a concavity + CoG of the concavity
        lafConstructsToUse_LAF__LAF_2TP_CCG = 0;

        % LAF_CG_CCG,          ///< 7: CM of DR + CoG of DR + CoG of concavity
        lafConstructsToUse_LAF__LAF_CG_CCG = 0;

        % LAF_CG_BT,           ///< 8: CM of DR + CoG of DR + bitangent direction
        lafConstructsToUse_LAF__LAF_CG_BT = 1;

        % LAF_CCG_BT,          ///< 9: CM of concavity + CoG of concavity + bitangent direction
        lafConstructsToUse_LAF__LAF_CCG_BT = 1;

        % LAF_CG_GRAD,         ///< 10: CM of DR + CoG of DR + dominant gradient direction
        lafConstructsToUse_LAF__LAF_CG_GRAD = 0;

        % LAF_JUNCTION,        ///< 11: junctions (not used with MSERs)
        lafConstructsToUse_LAF__LAF_JUNCTION = 1;

        % LAF_CG_VERTICAL,     ///< 12: CM of DR + CoG of DR + vertical direction
        lafConstructsToUse_LAF__LAF_CG_VERTICAL = 0;

        % LAF_AFFINE_POINT_ORIENTATION, ///< 13: not used with MSERs
        lafConstructsToUse_LAF__LAF_AFFINE_POINT_ORIENTATION = 1;

        % LAF_LOWE_KEYPOINT,            ///< 14: not used with MSERs
        lafConstructsToUse_LAF__LAF_LOWE_KEYPOINT = 0;

        % LAF_CG_LINEAR_SEGMENT_DIR,    ///< 15: CM of DR + CoG of DR + direction of a linear segment of the DR boundary
        lafConstructsToUse_LAF__LAF_CG_LINEAR_SEGMENT_DIR = 0;

        % LAF_CG_INFLECTION,   ///< 16: CM of DR + CoG of DR + inflection point of the contour
        lafConstructsToUse_LAF__LAF_CG_INFLECTION = 0;

        % LAF_CG_HCG,          ///< 17: CM of DR + CoG of DR + CoG of a region hole
        lafConstructsToUse_LAF__LAF_CG_HCG = 0;

        % LAF_HCG_CG,          ///< 18: CM of a region hole + CoG of of the hole + CoG of DR
        lafConstructsToUse_LAF__LAF_HCG_CG = 0;

        % LAF_CG_THIRD_MOMENT, ///< 19: CM of DR + CoG of DR + direction obtained from third moments
        lafConstructsToUse_LAF__LAF_CG_THIRD_MOMENT = 0;

        % LAF_CG_DIST_MAX,     ///< 20: CM of DR + CoG of DR + point of maximal distance on normalised contour
        lafConstructsToUse_LAF__LAF_CG_DIST_MAX = 0;

        % LAF_CG_DIST_MIN,     ///< 21: CM of DR + CoG of DR + point of minimal distance on normalised contour
        lafConstructsToUse_LAF__LAF_CG_DIST_MIN = 0;
        %forestFname = [evalin('base = 'start_path') '/desc/lafs/decisionForest'])

        % lafdetector
        minMargin = 1;
        minSize = 30;
        maxPercent = .1;
        stability = 8;
        minOverlap = .25;
        minLevelOverlap = .15;
        suppressOverlap = .3;

        %      GLOBAL_CONSISTENCY_NONE = 0, ///< 0: No TC pruning

        %      GLOBAL_CONSISTENCY_TUYTELAARS, ///< 1: method by Tinne Tuytelaars,
        %      it never worked

        %      GLOBAL_CONSISTENCY_MULTIPLE_PLANES, ///< 2: a TC is kept if at least
        %      parameters.matchingNConsistent other TCs have similar transformation

        %      GLOBAL_CONSISTENCY_BEST_PLANE, ///< 3: only a maximal subset of TCs
        %      that have similar transformation is kept.
        matchingGlobalConsistencyType = 'GLOBAL_CONSISTENCY_MULTIPLE_PLANES';

        %      MATCHING_STRATEGY_ALL_NEAR, ///< 1: TC: query frame <-> all DB
        %      frames that are closer the the query one than
        %      parameters.matchingMaximalInterestingDistance

        %      MATCHING_STRATEGY_NEAREST, ///< 2: TC: query frame <-> closest of DB
        %      frames, if closer than parameters.matchingMaximalInterestingDistance

        %      MATCHING_STRATEGY_BIDIRECTIONAL_NEAREST, ///< 3: TC: query frame <->
        %      closest of DB frames together with DB frame <-> closest query frame

        %      MATCHING_STRATEGY_MUTUALLY_NEAREST, ///< 4: TC: query frame <->
        %      closest of DB frames if simultaneously DB frame <-> closest query
        %      frame

        %      MATCHING_STRATEGY_N_NEAREST, ///< 5: TC: query frame <-> up to
        %      parameters.matchingNNearest closest DB frames
        matchingStrategy = 'MATCHING_STRATEGY_MUTUALLY_NEAREST';

        % pro kazdy DBF ramec pocet blizkych ramcu  ze sceny do pairedIndices
        matchingNNearest = 2;

        % pocet konzistentnich pri overovani globalni konzistence
        matchingNConsistent = 4;

        % true ma-li byt pouzita normalizovana korelace
        matchingNormalizedCorrelation = 1;

        % transformace jednotlivych bar. kanalu: y = a(x + b)
        matchingAllowedIntensityScale = 4; % = 1.5, pomer prumernych intensit v jednotlivych kanalech ~ a
        matchingAllowedIntensityOffset = 999; % = 50, rozdil prumernych intensit v jednotlivych kanalech ~ b
        matchingAllowedChromaticityChange = 0.1; % = 0.1, maximalni vzd. prumerne barvy na chromaticke rovine

        % default = 0.5 0..1
        matchingMaximalInterestingDistance = 0.2;

        % unused 
        matchingMaximalDiscriminantDifference = 999.5;

        % default = 4*4,     ! druha mocnina ! maximalni povolena hodnota determinantu transformacni matice model -> obraz
        matchingMaximalModelToImageScale = 16;

        % default = 0.25*0.25, ! druha mocnina ! minimalni povolena hodnota determinantu transformacni matice model -> obraz
        matchingMinimalModelToImageScale = 0.0625;

        % defalt = 3 maximalni povoleny pomer vl. cisel transformacni matice model -> obraz
        matchingMaximalAnisotropicScale = 4;

        % default = M_PI/18  povoleny uhel projekce svisle osy
        matchingMaximalHorizontalDeviation = 6.28319;

        % 0..1, 1 pro vsechny nejblizsi matche
        matchingMaximalFirstAndSecondDistanceRatio = 0.99;

        % dirty hack, leaving only one corespondence per each DR pair
        matchingOneCorrespondencePerDR = 0;
        verbose = 0;

        % we don't want to accidentally get different settings when in directory with lafs.cfg
        ignoreLafsCfg = 1;
        skipRasterisationAndDescription = 1;
        outputFormat = 1;
    end

    methods
        function this = Laf(varargin)
            this = this@CfgBase(varargin{:});
            if ~isempty(varargin)
                this = cmp_argparse(this,varargin{:});
            end
        end
    end

    methods(Static)
        function uname = get_uname()
            uname = LAF.CFG.Laf.uname;
        end
    end
end 
