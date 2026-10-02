#import "Hash_Table";
#import "Basic";

/*

The main usage is for when you have some memory which can't be managed directly by alloc

I use this for gpu buffers.

*/
First_Fit_Virtual_Allocator :: struct {
    size : u32;

    // id_to_owned_region : Table(int, [2] u32);
    // these intervals include the start index and exclude the end index.
    occupied_intervals : [..] [2] u32;
}

deinit :: (using ffva : *First_Fit_Virtual_Allocator) {
    array_free(occupied_intervals);
    size = 0;
}

get_size_of_previous_alloc :: (using ffva : *First_Fit_Virtual_Allocator, index: u32) -> size: u32, success: bool {

    for occupied_intervals 
        // if you had the interval [0, 4) which contains 4 elts, then 4 - 0 = 4 which is correct.
        if it[0] == index return it[1] - it[0], true;

    return 0, false;
}

// note: the start index is your pointer
// todo: should this just be called t
virtual_alloc :: (using ffva : *First_Fit_Virtual_Allocator, length: u32) -> start_index: u32, success: bool {
    last_end : u32 = 0;

    for idx : 0..occupied_intervals.count-1 {
        start := occupied_intervals[idx][0];
        end := occupied_intervals[idx][1];

        if (start - last_end >= length) {
            interval := u32.[last_end, last_end + length];
            array_insert_at(*occupied_intervals, interval, idx);
            return last_end, true;
        }
        last_end = end;
    }

    if (size - last_end >= length) {
        interval := u32.[last_end, last_end + length];
        array_add(*occupied_intervals, interval);
        return last_end, true;
    }

    return 0, false;
}

virtual_free :: (using ffva : *First_Fit_Virtual_Allocator, start_index: u32) -> bool {
    for 0..occupied_intervals.count-1 {
        interval := occupied_intervals[it];
        if (interval[0] == start_index) {
            array_ordered_remove_by_index(*occupied_intervals, it);
            return true;
        }
    }
    return false;
}











