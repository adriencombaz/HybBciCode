int LevinsonDurbinAlgorithm(
        const VECTORN_REAL<REAL>& vArSequence,
        int denominatorDegree,
        VECTORN_BASE<VECTORN_REAL<REAL> >& vArCoefficients,
        VECTORN_REAL<REAL>& vReflectionCoefficients,
        VECTORN_REAL<REAL>& vPredictionError
        )
{
	int m, k, err;
    int nElems = vArSequence.GetNumElems();
	REAL fDelta,km;

    //The autocorrelation sequence (minimum size P+1).
	CHECK_ARG_RIE( nElems <= denominatorDegree );

    //The vector with the prediction error for a predictor of up to order P (vector size P+1).
	//Store all values.
	CALL_RIE( vPredictionError.InitVector( denominatorDegree + 1 ) );	
	CALL_RIE( vReflectionCoefficients.InitVector( denominatorDegree ) );

	//The coefficients of a predictor of up to order P (P+1 vectors with size from 1 till P+1),
	CALL_RIE( vArCoefficients.InitVector( denominatorDegree + 1 ) );

	//the coefficients of order P=0
	CALL_RIE( vArCoefficients[0].InitVector(1) );	//the coefficient a0(0)=1
	vArCoefficients[0][0] = 1.0f;
	vPredictionError[0] = vArSequence[0];            //the prediction error for a predictor of order P=0
	
	//the coefficients of order P=1
	CALL_RIE( vArCoefficients[1].InitVector(2) );//the coefficients a1(0)=1, a1(1)=?
    
	CHECK_DIVby0_RIE( vArSequence[0] );	//check division by 0
	vArCoefficients[1][0] = 1.0f;

    //km=vArSequence[1]/vArSequence[0];						//different to Durbin's algorithm for a predictor
	km = -vArSequence[1] / vArSequence[0];

    vArCoefficients[1][1] = km;

    //vReflectionCoefficients[0]=-km;							//different to Durbin's algorithm for a predictor
	vReflectionCoefficients[0] = km;
	
    vPredictionError[1] = vPredictionError[0] * ( 1.0f - km * km );//the prediction error for a predictor of order P=1
	

	for( m = 2; m <= denominatorDegree; ++m )//find all orders up to P
	{
		//the patial correlation
		fDelta = 0.0f;
		for( k = 1; k <= m-1; ++k )
		{
			fDelta += vArCoefficients[m-1][k] * vArSequence[m-k];
		}
		//fDelta=vArSequence[m]-fDelta;						//different to Durbin's algorithm for a predictor
		fDelta = vArSequence[m] + fDelta;

		CHECK_DIVby0_RIE( vPredictionError[m-1] );	//check division by 0
		//km=fDelta/vPredictionError[m-1];			//different to Durbin's algorithm for a predictor
		km = -fDelta / vPredictionError[m-1];
		//vReflectionCoefficients[m-1]=-km;								//different to Durbin's algorithm for a predictor
		vReflectionCoefficients[m-1] = km;

		//the coefficients of order P
		CALL_RIE( vArCoefficients[m].InitVector(m+1) );//the coefficients ap(0)=1, ap(1)=?, ap(2)=?,...
		vArCoefficients[m][0] = 1.0f;
		vArCoefficients[m][m] = km;
        
		for( k=1; k<m; ++k )	//find the rest of coefficients
		{
			//vArCoefficients[m][k]=vArCoefficients[m-1][k]-km*vArCoefficients[m-1][m-k];	
			vArCoefficients[m][k] = vArCoefficients[m-1][k] + km * vArCoefficients[m-1][m-k];			//different to Durbin's algorithm for a predictor
		}

		//the prediction error for a predictor of order P
		vPredictionError[m] = vPredictionError[m-1] * ( 1.0f - km * km );
	}
    
	return KR_OK;
}

#endif // __KR_SIGNAL_PROCESSING_LEVINSON_DURBIN_ALGORITHM_INL__
///@}