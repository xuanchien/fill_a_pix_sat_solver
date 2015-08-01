#please update this according to your system
MINISAT_PATH = "/usr/local/bin/minisat_release"

#Class contains all logic to generate CNF encoding
class PuzzleSolver
  def initialize(rows, columns)
    @rows = rows
    @columns = columns
    @global_counter_tseitin = rows * columns
  end

  def new_tseitin_var
    @global_counter_tseitin += 1
  end

  def to_cnf(dnf_clauses)
    cnf_clauses = []
    new_vars = []
    dnf_clauses.each do |clause|
      #implement tseitin conversion here
      #introduce new variable
      new_var = new_tseitin_var

      cnf_clauses += clause.map {|var| [-new_var, var]}

      new_vars << new_var
    end

    cnf_clauses << new_vars
  end

  #return all available boxes around cell i,j
  def available_variables(i, j)
    vars = []
    [0, -1, 1].each do |a|
      [0, -1, 1].each do |b|
        if (i + a > 0 && j + b > 0 && i + a <= @rows && j + b <= @columns)
          vars << (i-1 + a)*@columns + (j + b)
        end
      end
    end

    vars
  end

  def solve(grid)
    cnf_clauses = []

    (1..@rows).each do |i|
      (1..@columns).each do |j|
        k = grid[i-1][j-1]
        if k > -1
          vars = available_variables(i, j)

          #select all sets containing k elements in vars
          all_sets = vars.combination(k)

          #generate basic DNF clauses
          dnf_clauses = all_sets.map do |set|
            set + (vars - set).map{|x| -x}
          end

          if dnf_clauses.length == 1
            cnf_clauses += dnf_clauses[0].map{|c| [c]}
          else
            cnf_clauses += to_cnf(dnf_clauses)
          end
        end
      end
    end

    #write cnf clauses to CNF file

    File.open("cnf_config.txt", "w") do |f|
      f.puts "p cnf #{@global_counter_tseitin} #{cnf_clauses.length}"
      cnf_clauses.each do |clause|
        f.puts clause.join(' ') + " 0"
      end
    end
  end
end

if ARGV.length == 0
  puts "Please specify input file"
  exit
end

puts "Processing... Please wait!"
grid = []
File.foreach(ARGV.first) do |line|
  grid << line.split(/\s+/).map{|c| c == '.' ? -1 : c.to_i }
end

rows = grid.length
columns = grid[0].length

puzzle_solver = PuzzleSolver.new(rows, columns)
puzzle_solver.solve(grid)

#call miniSAT to solve the problem
`#{MINISAT_PATH} cnf_config.txt cnf_result.txt`

text = File.open("cnf_result.txt")
sat = text.readline.chomp

if sat == "SAT"
  puts "Solved!"
else
  puts "Can not solve this puzzle"
  exit
end

#Read solution from miniSAT output file and transform into human-readable form
solutions = text.readline.split(/\s+/).map(&:to_i)

output_filename = File.basename(ARGV.first, ".txt")
output_file = File.open("#{output_filename}_result.txt", "w")

(1..rows).each do |i|
  (1..columns).each do |j|
    if solutions[(i-1)*columns + j -1] > 0
      output_file.print "@ "
    else
      output_file.print ". "
    end
  end
  output_file.puts ""
end

output_file.close