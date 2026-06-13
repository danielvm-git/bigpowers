package org.jfree.date.junit;

import junit.framework.TestCase;
import org.jfree.date.*;
import static org.jfree.date.DayDate.*;

/**
 * Clean Code Reference: DayDateTest (Remediated)
 * 
 * Remediation Notes:
 * - T4: Commented-out tests converted to explicit Ambiguity Notes.
 * - G29: Conditionals in setup expressed as positives.
 */
public class DayDateTest extends TestCase {

    public void testIsValidWeekdayCode() throws Exception {
        for (int day = 1; day <= 7; day++) {
            assertTrue(Day.fromInt(day) != null);
        }
    }

    public void testStringToWeekdayCode() throws Exception {
        assertEquals(Day.MONDAY, Day.parse("Monday"));
        assertEquals(Day.MONDAY, Day.parse("Mon"));
        
        /*
         * T4 AMBIGUITY: Support for lowercase names?
         * Currently ignored because the requirements don't specify case-insensitivity 
         * for "monday" vs "Monday" in the initial draft.
         * TODO: Confirm with stakeholder if lowercase support is required.
         */
        // assertEquals(Day.MONDAY, Day.parse("monday"));
    }

    public void testLeapYearCount() throws Exception {
        assertEquals(0, DateUtil.leapYearCount(1900));
        assertEquals(1, DateUtil.leapYearCount(1904));
        assertEquals(24, DateUtil.leapYearCount(1999));
        assertEquals(25, DateUtil.leapYearCount(2001));
    }
}
