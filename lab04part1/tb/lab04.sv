
typedef struct {
    real x;
    real y;
} coordinates_s;



virtual class shape_c;

    string name;
    coordinates_s points[$];


    function new(string n, coordinates_s p[$]);
        name = n;
        points = p;
    endfunction 

    pure virtual function real get_area();

    function print();
        $display("This is: %s", name);
        foreach(points[i]) begin
            $display("(%f, %f)", points[i].x, points[i].y);
        end
        $display("Area: %f", get_area());
    endfunction
        
endclass


class polygon_c extends shape_c;

    function new(string name = "polygon", coordinates_s points[$]);
        super.new(name, points);
    endfunction

    function real get_area();
        real area = 0;


        for (int i=0; i < points.size(); i++) begin
            int j = (i + 1) % points.size();
            area = area + (points[i].x * points[j].y) - (points[j].x * points[i].y);
        end

        area = 0.5 * area;

        if (area < 0) begin
            area = -area;
        end

        return area;
    endfunction

endclass

class rectangle_c extends polygon_c;

    function new(coordinates_s points[$]);
        super.new("rectangle", points);
    endfunction

endclass


class triangle_c extends polygon_c;

    function new(coordinates_s points[$]);
        super.new("triangle", points);
    endfunction

endclass

class circle_c extends shape_c;

    function new(coordinates_s points[$]);
        super.new("circle", points);
    endfunction


    function real get_area();
        real radius, area;
        radius = get_radius();
        area = 3.14 * radius * radius;
        return area;
    endfunction

    function real get_radius();
        return $sqrt((points[1].x - points[0].x) * (points[1].x - points[0].x) + (points[1].y - points[0].y) * (points[1].y - points[0].y));
    endfunction

    function print();
        $display("This is: %s", name);
        foreach(points[i]) begin
            $display("(%f, %f)", points[i].x, points[i].y);
        end
        $display("Radius: %f", get_radius());
        $display("Area: %f", get_area());
    endfunction

endclass


class shape_factory_c;
    static function shape_c make_shape(coordinates_s points[$]);

        circle_c circle;
        triangle_c triangle;
        rectangle_c rectangle;
        polygon_c polygon;

        case (points.size())
            1 : begin
                $error();
            end
            2 : begin
                circle = new(points);
                return circle;
            end
            3 : begin
                triangle = new(points);
                return triangle;
            end
            4 : begin
                rectangle = new(points);
                return rectangle;
            end
            default : begin
                polygon = new("polygon", points);
                return polygon;
            end

        endcase

    endfunction

endclass


class shape_reporter_c #(type T = shape_c);
    protected static T shape_storage [$];

    static function void report_shapes();
        foreach (shape_storage[i]) begin
            shape_storage[i].print();
        end
    endfunction

    static function void add_shape(shape_c shape);
        shape_storage.push_back(shape);
    endfunction

endclass



module top;

    initial begin

        shape_factory_c shape_factory;
        shape_reporter_c shape_reporter;
        shape_c shape;
        int file_handle;
        string line, temp_string, tokens[$];
        coordinates_s coordiante, coordinates_queue[$];



        file_handle = $fopen("/home/student/jcichon/VIDIC_2025/lab04part1/tb/lab04part1_shapes.txt", "r");

        $fgets(line, file_handle);

        while (line != "") begin

            coordinates_queue = {};
            tokens = {};


            foreach (line[i]) begin
                if (line[i] == "\n") begin
                    tokens.push_back(temp_string);
                    temp_string = "";
                    break;
                end
                else if (line[i] == " ") begin
                    tokens.push_back(temp_string);
                    temp_string = "";
                end
                else begin
                    temp_string = {temp_string, line[i]};
                end

            end



            for (int j = 0; j < tokens.size(); j += 2) begin
                if (j + 1 < tokens.size()) begin
                    coordiante.x = tokens[j].atoreal();
                    coordiante.y = tokens[j+1].atoreal();
                    coordinates_queue.push_back(coordiante);
                end
            end


            shape = shape_factory.make_shape(coordinates_queue);

            shape_reporter.add_shape(shape);

            $fgets(line, file_handle);

        end

        shape_reporter.report_shapes();

    end

endmodule
