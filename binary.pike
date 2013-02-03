/*
Rules:
1. "Sequence rule": No three consecutive cells may have the same value.
2. "Parity rule": Every row and column contains equal numbers of 1s and 0s.
3: "Uniqueness rule": No two rows, and no two columns, may contain the exact same sequence of digits.

Corollaries:
* A pair of cells with the same value is bracketed by the opposite value: .11. --> 0110
* Two cells with the same value, separated by a gap, must be separated by the other value: 1.1 --> 101

State description:
array(string) state=
({
	"....",
	"....",
	"....",
	"....",
});
Each cell is . for unknown, or ASCII 0 or 1.
*/

//Flip rows and columns - simplifies some algorithms. Not promised to be fast, just simple. :)
array(string) flip(array(string) state) {return (array(string))Array.transpose((array(array(int)))state);}

//Validate a state, optionally including its structure (omit that for a quicker check when certain the structure hasn't been altered)
//Returns 0 if okay, else failure reason
string validate(array(string) state,int|void structure)
{
	if (structure)
	{
		int sz=sizeof(state);
		if (sz&1) return "Have to have an even number of rows/cols";
		foreach (state,string line) if (sizeof(line)!=sz) return "Have to be square";
	}
	int sz=sizeof(state);
	foreach (({state,flip(state)}),array(string) state)
	{
		//Validate rows, then columns.
		foreach (state;int i;string line)
		{
			if (search(line,"000")!=-1 || search(line,"111")!=-1) return "Sequence rule";
			if (sizeof(line/"0")-1>sz || sizeof(line/"1")-1>sz) return "Parity rule";
			if (search(line,'.')==-1 && search(state,line)<i) return "Uniqueness rule"; //Applicable only to completed lines. The rule will be violated by the second line in the state, which will be found earlier than its own index.
		}
	}
	return 0;
}

//Test validate() on a variety of example states
void valid(array(string) state) {if (!validate(state,1)) write("Correctly shows as valid:\n%s\n",state*"\n"); else write("WRONGLY MARKED INVALID:\n%s\n",state*"\n");}
void wrong(array(string) state) {if ( validate(state,1)) write("Correctly shows as invalid:\n%s\n",state*"\n"); else write("WRONGLY MARKED VALID:\n%s\n",state*"\n");}
int test_validate()
{
	valid(({"....","....","....","...."}));
	wrong(({"...."}));
	wrong(({"...","...","..."}));
	valid(({"1100","1010","0011","0101"}));
	wrong(({"1100","1100","0011","0011"}));
	wrong(({"1100","1010","1001","0110"}));
	valid(({
		"0110010110",
		"0110101010",
		"1001001101",
		"0010110011",
		"1101010100",
		"0110101001",
		"1001010110",
		"1010100110",
		"0101101001",
		"1001011001",
	}));
	valid(({
		"0.1.......",
		"0..0.01...",
		".00..0..0.",
		"....1....1",
		".1......0.",
		".....0....",
		"1.0....11.",
		".0...0.1..",
		"...11...0.",
		"........0.",
	}));
}

constant monitor=1;
void move(array(string) state,int val,int row,int col,string|void desc)
{
	if (state[row][col]!='.') error("OOPS! Can't set state where it's not currently blank");
	state[row][col]=val;
	if (!monitor) return;
	//write("\n%s\n",state*"\n"); sleep(.1);
	string s=state*"\n";
	int pos=row*(sizeof(state)+1)+col;
	write("\t\t\t%s\n%s\e[1m%c\e[0m%s\n",desc||"",s[..pos-1],s[pos],s[pos+1..]);
	sleep(.1);
}

//Try simple techniques to find a solution
//Tests only rows, not columns. Will be called again with a flipped state to check columns.
//Returns a three-tuple of ({value, row, col}) where value is '0' or '1' and row,col is where to put it (which will be inverted if state is flipped).
//If no simple move can be found, returns ({0,0,0}).
array(int) try_solve_simple(array(string) state)
{
	foreach (state;int i;string line)
	{
		if (search(line,'.')==-1) continue; //Nothing to do!
		int other='0';
		while (1)
		{
			int pos;
			pos=search(line,".11"); if (pos!=-1) return ({other,i,pos,".xx"});
			pos=search(line,"1.1"); if (pos!=-1) return ({other,i,pos+1,"x.x"});
			pos=search(line,"11."); if (pos!=-1) return ({other,i,pos+2,"xx."});
			if (sizeof(line/"1")-1 == sizeof(line)/2) return ({other,i,search(line,'.'),"parity-simple"}); //Can't have any more '1' so any remaining '.'s become a '0's

			if (other=='1') break;
			other='1'; line=replace(line,({"0","1"}),({"1","0"}));
			//And redo all these checks with 1 and 0 switched. Saves writing them out twice. Note that the array is not mutated, only the local line string.
		}
	}
	return ({0,0,0,0});
}

//Mutates state. Must not reassign state.
int try_solve(array(string) state)
{
	if (validate(state,1)) return 0; //Mucked-up state/structure, no good
	while (1)
	{
		if (validate(state)) return 0;
		[int val,int row,int col,string desc]=try_solve_simple(state);
		if (val) {move(state,val,row,col,desc); continue;}
		[val,row,col,desc]=try_solve_simple(flip(state));
		if (val) {move(state,val,col,row,desc+"-col"); continue;}
		if (search(state*"",'.')==-1) return 1; //Solved!
		break; //Probably not solvable.
	}
	//TODO: Try one space at random, recurse.
}

int main()
{
	//test_validate();
	array(string) state=({ //A fairly easy puzzle
		"0.1.......",
		"0..0.01...",
		".00..0..0.",
		"....1....1",
		".1......0.",
		".....0....",
		"1.0....11.",
		".0...0.1..",
		"...11...0.",
		"........0.",
	});
	if (validate(state,1)) write("Bad state\n");
	try_solve(state);
	write(" %s\n",replace(state*"\n",""," "));
}
